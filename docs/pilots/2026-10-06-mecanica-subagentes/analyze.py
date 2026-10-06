#!/usr/bin/env python3
import json, sys, os, glob, statistics
D = sys.argv[1]
RUNS = sys.argv[2] if len(sys.argv)>2 else 'runs'
def load(p):
    out=[]
    with open(p) as f:
        for line in f:
            try: out.append(json.loads(line))
            except Exception: pass
    return out
def ts(e):
    from datetime import datetime
    t=e.get('timestamp');
    return datetime.fromisoformat(t.replace('Z','+00:00')).timestamp() if t else None
rows=[]
for R in sorted(glob.glob(os.path.join(D,RUNS,'r*'))):
    rid=os.path.basename(R); arm=open(os.path.join(R,'arm')).read().strip()
    files=glob.glob(os.path.join(R,'home/.codex/sessions/*/*/*/*.jsonl'))
    parent=None; children=[]
    for f in files:
        ev=load(f); meta=next((e['payload'] for e in ev if e.get('type')=='session_meta'),{})
        src=meta.get('source')
        if isinstance(src,dict) and 'subagent' in src: children.append((f,ev,meta))
        else: parent=(f,ev,meta)
    r={'run':rid,'arm':arm}
    def rd(n):
        p=os.path.join(R,n); return open(p).read().strip() if os.path.exists(p) else ''
    r['exit']=rd('exit'); r['killed']='yes' if os.path.exists(os.path.join(R,'killed')) else 'no'
    st,en=rd('start'),rd('end')
    r['wall_s']=int(en)-int(st) if st and en else None
    if parent is None:
        rows.append(r); continue
    ev=parent[1]
    # token usage & model calls
    tc=[e['payload'] for e in ev if e.get('type')=='event_msg' and e['payload'].get('type')=='token_count' and e['payload'].get('info')]
    calls=0; last=None
    for p in tc:
        tot=p['info']['total_token_usage']['total_tokens']
        if tot!=last: calls+=1; last=tot
    u=tc[-1]['info']['total_token_usage'] if tc else {}
    r['lead_calls']=calls
    r['lead_in']=u.get('input_tokens',0); r['lead_cached']=u.get('cached_input_tokens',0)
    r['lead_uncached']=r['lead_in']-r['lead_cached']; r['lead_out']=u.get('output_tokens',0)
    r['lead_uncached_plus_out']=r['lead_uncached']+r['lead_out']
    fcs=[e['payload'] for e in ev if e.get('type')=='response_item' and e['payload'].get('type') in ('function_call','custom_tool_call')]
    outs={e['payload'].get('call_id'):e['payload'].get('output') for e in ev if e.get('type')=='response_item' and e['payload'].get('type') in ('function_call_output','custom_tool_call_output')}
    names={}
    for fc in fcs: names[fc.get('name')]=names.get(fc.get('name'),0)+1
    r['tool_calls']=json.dumps(names,sort_keys=True)
    seq=[fc.get('name') for fc in fcs]
    waits=[fc for fc in fcs if fc.get('name')=='wait_agent']
    r['waits']=len(waits); to=0; bounds=[]
    for w in waits:
        o=outs.get(w.get('call_id'))
        if o and '"timed_out":true' in (o if isinstance(o,str) else json.dumps(o)): to+=1
        try: bounds.append(json.loads(w.get('arguments','{}')).get('timeout_ms'))
        except Exception: pass
    r['wait_timeouts']=to; r['wait_bounds_ms']=','.join(str(b) for b in bounds)
    spawns=[fc for fc in fcs if fc.get('name')=='spawn_agent']
    r['spawns']=len(spawns)
    fw=seq.index('wait_agent') if 'wait_agent' in seq else len(seq)
    r['spawns_before_first_wait']=sum(1 for n in seq[:fw] if n=='spawn_agent')
    at=[];fk=[];ovr=0
    for s in spawns:
        try: a=json.loads(s.get('arguments','{}'))
        except Exception: a={}
        at.append(a.get('agent_type','-')); fk.append(str(a.get('fork_turns', a.get('fork_context','-'))))
        if 'model' in a or 'reasoning_effort' in a: ovr+=1
    r['agent_types']=','.join(at); r['fork']=','.join(fk); r['spawn_overrides']=ovr
    r['list_agents']=names.get('list_agents',0); r['send_message']=names.get('send_message',0)
    # children
    cm=[];ctok=0;cdone=0
    for f,cev,meta in children:
        # Turnos propios del hijo: ordinal >= subagent_history_start_ordinal. En un fork, los
        # turn_context anteriores son la historia copiada del padre (y llevan el modelo del padre).
        start=meta.get('subagent_history_start_ordinal') or 0
        tcx=[e['payload'] for e in cev if e.get('type')=='turn_context' and (e.get('ordinal') or 0)>=start]
        m=tcx[0].get('model') if tcx else '-'; ef=tcx[0].get('effort') if tcx else '-'
        role=meta.get('agent_role','-'); cm.append(f"{role}:{m}/{ef}")
        ctc=[e['payload'] for e in cev if e.get('type')=='event_msg' and e['payload'].get('type')=='token_count' and e['payload'].get('info')]
        if ctc:
            cu=ctc[-1]['info']['total_token_usage']; ctok+=cu.get('input_tokens',0)-cu.get('cached_input_tokens',0)+cu.get('output_tokens',0)
        if any(e.get('type')=='event_msg' and e['payload'].get('type')=='task_complete' for e in cev): cdone+=1
    ins=' '.join(str(e['payload'].get('input','')) for e in ev if e.get('type')=='response_item' and e['payload'].get('type')=='custom_tool_call')
    outs_txt=' '.join(str(e['payload'].get('output','')) for e in ev if e.get('type')=='response_item' and e['payload'].get('type')=='custom_tool_call_output')
    r['real_repo_reads']=ins.count(os.path.expanduser('~/agent-scaffolding/')) - ins.count(os.path.expanduser('~/agent-scaffolding/.worktrees/pilot'))
    r['saw_fork_rule']='yes' if 'Nunca forkees' in outs_txt else 'no'
    r['forked_children']=sum(1 for f,cev,meta in children if meta.get('forked_from_id'))
    r['children']=len(children); r['children_done']=cdone; r['children_models']=';'.join(sorted(set(cm)))
    r['children_uncached_plus_out']=ctok
    t0=ts(ev[0]); t1=max(ts(e) for e in ev if e.get('timestamp'))
    r['lead_span_s']=int(t1-t0) if t0 and t1 else None
    la=rd('last.txt'); r['final_chars']=len(la)
    r['target_clean']='yes' if rd('target_status.txt')=='' else 'NO'
    rows.append(r)
cols=['run','arm','exit','killed','wall_s','lead_span_s','lead_calls','lead_uncached','lead_out','lead_uncached_plus_out','lead_cached','waits','wait_timeouts','wait_bounds_ms','spawns','spawns_before_first_wait','agent_types','fork','spawn_overrides','list_agents','send_message','children','children_done','children_models','children_uncached_plus_out','final_chars','target_clean','real_repo_reads','saw_fork_rule','forked_children','tool_calls']
with open(os.path.join(D,'metrics_'+RUNS+'.tsv'),'w') as f:
    f.write('\t'.join(cols)+'\n')
    for r in rows: f.write('\t'.join('' if r.get(c) is None else str(r.get(c,'')) for c in cols)+'\n')
for r in rows:
    print({k:r.get(k) for k in cols if k!='tool_calls'})
# medians
for arm in ('A','B'):
    rs=[r for r in rows if r['arm']==arm and r.get('lead_calls') is not None and r.get('exit')!='']
    if not rs: continue
    print(arm, 'n=',len(rs), {k: statistics.median([r[k] for r in rs]) for k in ['wall_s','lead_calls','lead_uncached_plus_out','waits','wait_timeouts','spawns','children_uncached_plus_out']})
