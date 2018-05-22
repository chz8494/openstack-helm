We must dump all pool data to this file to trigger a resync.
Otherwise, confd notices the file hasn't changed and won't
run our python update script.

{{`{{range ls "/pool"}}`}}{{`{{$data := json (getv (printf "/pool/%s" .))}}`}}
  {{`{{if $data.ipip}}`}}{{`{{if not $data.disabled}}`}}{{`{{$data.cidr}}`}}{{`{{end}}`}}{{`{{end}}`}}
{{`{{end}}`}}
