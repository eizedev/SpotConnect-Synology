# Pull Request

## Summary

<!-- What does this change, and why? -->

## Test plan

<!--
How did you verify this? If you tested on real hardware, say which model and
DSM/SRM version - platform behaviour in this project has repeatedly turned out
to differ from what seemed like a reasonable assumption, particularly between
DSM and SRM.
-->

- [ ] `cd src/dsm7 && make shellcheck` passes
- [ ] Package builds (`ARCH=<arch> make clean build`)
- [ ] `tests/validate_spk.sh` passes against the built package
- [ ] Tested on real hardware, or explicitly not (say which)
- [ ] `CHANGELOG.md` updated, if this changes behaviour users can notice
