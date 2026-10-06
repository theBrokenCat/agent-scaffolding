#!/usr/bin/env python3
# Metricas del piloto Claude a partir de stream.jsonl (claude -p --output-format stream-json --verbose)
import json, sys, os, glob, statistics, re
C = sys.argv[1]
RUNS = sys.argv[2] if len(sys.argv)>2 else 'runs'
def load(p):
    out=[]
    for line in open(p):
        try: out.append(json.loads(line))
        except Exception: pass
    return out
rows=[]
for R in sorted(glob.glob(os.path.join(C,RUNS,'r*'))):
    ev=load(os.path.join(R,'stream.jsonl'))
    rd=lambda n: open(os.path.join(R,n)).read().strip() if os.path.exists(os.path.join(R,n)) else ''
    r={'run':os.path.basename(R),'arm':rd('arm'),'exit':rd('exit'),'killed':'yes' if os.path.exists(os.path.join(R,'killed')) else 'no'}
    st,en=rd('start'),rd('end'); r['wall_s']=int(en)-int(st) if st and en else None
    lead={}; sub={}; agent_calls=[]; lead_tools={}
    for e in ev:
        if e.get('type')!='assistant': continue
        m=e.get('message',{}); mid=m.get('id'); p=e.get('parent_tool_use_id')
        tgt = sub.setdefault(p,{}) if p else lead
        tgt.setdefault(mid,{'model':m.get('model'),'usage':m.get('usage',{}),'tools':[]})
        for c in m.get('content',[]) or []:
            if isinstance(c,dict) and c.get('type')=='tool_use':
                tgt[mid]['tools'].append(c)
                if not p:
                    lead_tools[c['name']]=lead_tools.get(c['name'],0)+1
                    if c['name'] in ('Agent','Task'):
                        agent_calls.append({'id':c['id'],'msg':mid,'type':c['input'].get('subagent_type'),'model':c['input'].get('model'),'bg':c['input'].get('run_in_background')})
    r['lead_calls']=len(lead)
    u=lambda d,k: sum((v['usage'] or {}).get(k,0) or 0 for v in d.values())
    r['lead_in_uncached']=u(lead,'input_tokens')+u(lead,'cache_creation_input_tokens'); r['lead_cache_read']=u(lead,'cache_read_input_tokens'); r['lead_out']=u(lead,'output_tokens')
    r['lead_uncached_plus_out']=r['lead_in_uncached']+r['lead_out']
    r['agent_calls']=len(agent_calls)
    r['agent_types']=','.join(str(a['type']) for a in agent_calls)
    r['model_overrides']=','.join(str(a['model']) for a in agent_calls if a['model']) or '-'
    r['bg_param']=','.join(str(a['bg']) for a in agent_calls)
    msgs={}
    for a in agent_calls: msgs.setdefault(a['msg'],0); msgs[a['msg']]+=1
    r['agent_batches']=len(msgs)  # mensajes del lead que contienen llamadas Agent
    r['sub_models']=';'.join(sorted({f"{a['type']}:{'/'.join(sorted({v['model'] for v in sub.get(a['id'],{}).values()}))}" for a in agent_calls}))
    r['sub_calls']=sum(len(v) for v in sub.values())
    r['sub_uncached_plus_out']=sum(u(v,'input_tokens')+u(v,'cache_creation_input_tokens')+u(v,'output_tokens') for v in sub.values())
    res=[e for e in ev if e.get('type')=='result']
    last=res[-1] if res else {}
    r['results']=len(res); r['cost_usd']=round(last.get('total_cost_usd',0) or 0,3)
    ss=last.get('subagent_stats',{}) or {}
    r['spawned']=ss.get('spawned'); r['started_bg']=ss.get('started_in_background'); r['nested']=ss.get('spawned_by_subagents'); r['by_type']=json.dumps(ss.get('by_type',{}),sort_keys=True)
    den=[d for e in res for d in (e.get('permission_denials') or [])]
    r['denials']=len(den); r['denied_real_repo']=sum(1 for d in den if os.path.expanduser('~/agent-scaffolding') in json.dumps(d))
    r['lead_tools']=json.dumps(lead_tools,sort_keys=True)
    txt=last.get('result','') or ''
    open(os.path.join(R,'last.txt'),'w').write(txt)
    r['final_chars']=len(txt); r['is_error']=last.get('is_error')
    r['read_manual']='yes' if any('agents/README.md' in json.dumps(t.get('input',{})) for v in lead.values() for t in v['tools']) else 'no'
    init=next((e for e in ev if e.get('type')=='system' and e.get('subtype')=='init'),{})
    r['fichas_disponibles']='yes' if 'explorer-economy' in (init.get('agents') or []) else 'no'
    r['target_clean']='yes' if rd('target_status.txt')=='' else 'NO'
    rows.append(r)
cols=['run','arm','exit','killed','is_error','wall_s','lead_calls','lead_uncached_plus_out','lead_cache_read','cost_usd','agent_calls','agent_batches','agent_types','model_overrides','bg_param','sub_models','sub_calls','sub_uncached_plus_out','spawned','started_bg','nested','by_type','results','denials','denied_real_repo','read_manual','final_chars','target_clean','fichas_disponibles','lead_tools']
with open(os.path.join(C,'metrics_claude_'+RUNS+'.tsv'),'w') as f:
    f.write('\t'.join(cols)+'\n')
    for r in rows: f.write('\t'.join('' if r.get(c) is None else str(r.get(c)) for c in cols)+'\n')
for r in rows: print({k:r.get(k) for k in cols})
for arm in ('A','B'):
    rs=[r for r in rows if r['arm']==arm and r.get('exit')!='']
    if rs: print(arm,'n=',len(rs),{k:statistics.median([r[k] for r in rs]) for k in ['wall_s','lead_calls','lead_uncached_plus_out','cost_usd','agent_calls','sub_calls']})
