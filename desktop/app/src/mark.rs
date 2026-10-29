// SPDX-License-Identifier: GPL-3.0-or-later
//! The Tokkip Phone mark: Tokkip on a blue tile (`assets/brand/icon-512.png`).
//! Kept here at 256 × 256 as raw RGBA and scaled to whatever size is asked
//! for: the tray, window and toast icons at runtime, and the executable's icon
//! at build time (`build.rs` includes this file).

/// The mark at 256 × 256, straight-alpha RGBA, row by row.
const SOURCE: &[u8] = include_bytes!("../../../assets/brand/tokkip-256.rgba");
const SOURCE_SIZE: usize = 256;

/// Renders the mark as straight-alpha RGBA, row by row, `size`×`size`.
/// Smaller sizes average every source pixel they cover (sharp, no shimmer);
/// larger ones are interpolated.
pub fn render(size: usize) -> Vec<u8> {
    let size = size.max(1);
    let mut out = vec![0u8; size * size * 4];
    let scale = SOURCE_SIZE as f32 / size as f32;
    for y in 0..size {
        for x in 0..size {
            let (x0, x1) = (x as f32 * scale, (x + 1) as f32 * scale);
            let (y0, y1) = (y as f32 * scale, (y + 1) as f32 * scale);
            // Premultiplied sums, weighted by how much of each source pixel is covered.
            let mut acc = [0f32; 4];
            let mut weight = 0f32;
            let mut sy = y0.floor() as usize;
            while (sy as f32) < y1 && sy < SOURCE_SIZE {
                let wy = (y1.min(sy as f32 + 1.0) - y0.max(sy as f32)).max(0.0);
                let mut sx = x0.floor() as usize;
                while (sx as f32) < x1 && sx < SOURCE_SIZE {
                    let wx = (x1.min(sx as f32 + 1.0) - x0.max(sx as f32)).max(0.0);
                    let w = wx * wy;
                    let i = (sy * SOURCE_SIZE + sx) * 4;
                    let a = SOURCE[i + 3] as f32 / 255.0;
                    acc[0] += SOURCE[i] as f32 * a * w;
                    acc[1] += SOURCE[i + 1] as f32 * a * w;
                    acc[2] += SOURCE[i + 2] as f32 * a * w;
                    acc[3] += a * w;
                    weight += w;
                    sx += 1;
                }
                sy += 1;
            }
            let o = (y * size + x) * 4;
            if weight > 0.0 && acc[3] > 0.0 {
                out[o] = (acc[0] / acc[3]).round().clamp(0.0, 255.0) as u8;
                out[o + 1] = (acc[1] / acc[3]).round().clamp(0.0, 255.0) as u8;
                out[o + 2] = (acc[2] / acc[3]).round().clamp(0.0, 255.0) as u8;
                out[o + 3] = (acc[3] / weight * 255.0).round().clamp(0.0, 255.0) as u8;
            }
        }
    }
    out
}

#[cfg(test)]
mod tests {
    use super::*;

    fn pixel(img: &[u8], size: usize, x: usize, y: usize) -> [u8; 4] {
        let i = (y * size + x) * 4;
        [img[i], img[i + 1], img[i + 2], img[i + 3]]
    }

    #[test]
    fn the_source_is_whole() {
        assert_eq!(SOURCE.len(), SOURCE_SIZE * SOURCE_SIZE * 4);
    }

    #[test]
    fn corners_are_transparent_and_tokkip_is_in_the_middle() {
        for size in [16, 32, 64, 256, 512] {
            let img = render(size);
            assert_eq!(img.len(), size * size * 4);
            assert_eq!(pixel(&img, size, 0, 0)[3], 0, "rounded corner at {size}");
            let face = pixel(&img, size, size / 2, size * 3 / 5);
            assert_eq!(face[3], 255, "opaque at {size}");
            assert!(face[0] > 0xC0 && face[1] > 0xC0, "Tokkip's cream face at {size}: {face:?}");
        }
    }

    #[test]
    fn the_tile_is_blue() {
        let img = render(64);
        let tile = pixel(&img, 64, 6, 32);
        assert!(tile[2] > tile[0] && tile[3] == 255, "{tile:?}");
    }
}
