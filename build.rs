fn main() {
    println!("cargo:rustc-link-search=native=target");
    println!("cargo:rustc-link-lib=static=boot");
}
