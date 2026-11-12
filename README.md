# crowsnest-module

A CrowsNest game module published from a source, for testing "Game modules from a source" end to end.

- `7dtd/module.yaml` + `module.yaml.sig`: 7 Days to Die (`didstopia/7dtd-server`), id `sevendtd`.
- `testdata/sevendtd_session.log`: a hand-written log for `crowsnest module check`.
- `publisher.key` is the signing key (git-ignored; keep it private).

Check and re-sign after any edit (the signature covers the exact bytes):

    crowsnest module check 7dtd/module.yaml --log testdata/sevendtd_session.log
    crowsnest module sign 7dtd/module.yaml --key publisher.key

Trust the key in the panel's `config.yaml`:

    managed:
      trusted_keys:
        - {name: publisher, public_key: OzuKyYzMpWBZrFtKy9MMumlEY5isVbJI/MVrL4sJCyk=}

Publish both files at one public https address (the panel refuses private ones), e.g. push this repo to GitHub and use
`https://raw.githubusercontent.com/<user>/crowsnest-module/main/7dtd/module.yaml`; the `.sig` must sit beside it.
The image must also be listed in the panel's `policy.yaml` before a game from the module can start.
