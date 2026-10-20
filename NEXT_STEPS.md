# Next steps

1. **Repository access:** obtain an empty accessible repository from the user. The current authenticated GitHub connection can access existing repositories but rejected creation. Set `origin` to the approved repository and push the committed source; do not substitute an unrelated repository.
2. **Remote build:** trigger the included Android workflow. Confirm test completion and artifact upload. The workflow is supplied but has not executed on GitHub yet.
3. **Physical device:** install the APK on the intended 6 GB Samsung phone. Complete the intro quest, test both vehicles, touchscreen multitouch, background/resume, save recovery and both interiors.
4. **Profile:** record frame times, RAM, temperature, battery and load time over at least 20 minutes per graphics preset. Current MultiMesh batching is a performance measure, not a measured FPS guarantee.
5. **Art and world expansion:** replace/augment simple primitive character and vehicle geometry with original detailed models, richer animations, more facade variation, road furniture, denser neighbourhoods and audio. Current traffic is parked scenery and pedestrians follow simple decorative paths.
6. **Long-run economy:** simulate and play through business scaling to ₦1 billion. Add more investment controls, progression uses for reputation, richer financial-event choices and tuning based on playtests.
7. **Persistence:** add multiple save slots, schema migrations, exact parked-car transforms and Android fault-injection tests around storage exhaustion and process kills.
8. **Input/UI polish:** physical notches and unusual aspect ratios, longer touch playtests, deeper vehicle camera transitions, and more graceful blocked-exit handling.
9. **Release work:** only after user approval, introduce a protected release signing key and store build configuration. No release publishing is authorized or performed by this delivery.

To resume: open `project.godot`, read `BUILD_STATUS.md`, run `bash tools/validate.sh`, and use `docs/ANDROID_BUILD.md` for export. Source, source-control history and an APK are local deliverables even while GitHub creation remains blocked.
