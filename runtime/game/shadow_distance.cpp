// SpeedBreaker runtime. GPL-3.0-or-later (see COPYING).
//
// Shadow Distance (settings Id::ShadowDistance). The shadow maps' range is
// the guest float at 0x828FCC74, the far distance of the camera frustum the
// shadow code fits its maps to (0x828FCC70, 0, is the near). The game sets it
// to 31.0 or 70.0 (0x82443A0C and 0x82443A74, the shadow setup sub_824439B0;
// 0x824756E0, a reset) and its tweakable-value objects can write it
// (0x8238B618, 0x8238B658), so rather than overwrite it the three reads
// are scaled, all by the same factor:
//   - 0x824561F4 and 0x82456358, in the shadow-map view setup sub_82456030
//     (the projection's far / (far - near), and the split geometric mean);
//   - 0x82455374, in its sibling sub_82455238.
// Hooks (config/nfsmw.toml; a hook runs before the instruction at its address,
// so each sits on the instruction after the load, the loaded register being
// the one scaled):
//   ShadowDistanceA  address 0x824561F8  registers f12  (after `lfs f12,-0x338c(r28)` at 0x824561F4)
//   ShadowDistanceB  address 0x8245635C  registers f12  (after `lfs f12,-0x338c(r28)` at 0x82456358)
//   ShadowDistanceC  address 0x82455378  registers f0   (after `lfs f0,-0x338c(r11)` at 0x82455374)
// Not touched: SHADOWMAP_LOD_DISTANCE (shader param 0x77, set from the shared
// 0.9 at 0x8205E240 at 0x82451184), which looks like a fraction, not a distance.
#include <stdafx.h>
#include <user/settings.h>

void ShadowDistanceA(PPCRegister& f12)
{
    f12.f64 = double(float(f12.f64) * std::clamp(settings::GetFloat(settings::Id::ShadowDistance), 1.0f, 4.0f));
}

void ShadowDistanceB(PPCRegister& f12) { ShadowDistanceA(f12); }

void ShadowDistanceC(PPCRegister& f0) { ShadowDistanceA(f0); }
