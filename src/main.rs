#![no_std]
#![no_main]
#![feature(lang_items)]
#![feature(core_intrinsics)]

pub mod rust;

#[no_mangle]
pub extern "C" fn kernel_main() {
    unsafe {
        *(0xb8000 as *mut u32) = 0x2f4b2f4f;
    }
}
