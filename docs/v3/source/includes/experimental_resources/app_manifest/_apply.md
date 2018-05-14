### Apply an app manifest
> **Note:** Apply manifest will only trigger an immediate update for the "disk_quota", "instances", and "memory" properties. All other properties will update on application restart.

Apply changes specified in a manifest to an app and its underlying processes. These changes are additive and will not modify any unspecified properties or remove any existing environment variables, routes, or services.

```
Example Request
```

```shell
curl "https://api.example.org/v3/apps/[guid]/actions/apply_manifest" \
  -X POST \
  -H "Authorization: bearer [token]" \
  -H "Content-type: application/x-yaml" \
  --data-binary @/path/to/manifest.yml
```

```
Example Response
```

```http
HTTP/1.1 202 Accepted
Location: https://api.example.org/v3/jobs/[guid]
```

#### Definition
`POST /v3/apps/:guid/actions/apply_manifest`

#### Allowed Roles
 |
--- | ---
Space Developer |
Admin |
