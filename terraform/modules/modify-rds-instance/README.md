## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| is\_prod | Flag used to determine whether to create prod or non-prod resources | string | `"true"` | no |
| rds\_instance\_class | The target instance class that need to be modified to. | string | n/a | yes |
| tag\_filters | A String giving tag name and value for all the filters. Follow the pattern {'Key1':'Value1','Key2':'Value2'} | string | n/a | yes |

