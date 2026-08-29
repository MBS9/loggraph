use wasm_bindgen::prelude::*;
use std::panic;
use std::panic::PanicHookInfo;

#[wasm_bindgen]
extern "C" {
    fn alert(s: &str);
    #[wasm_bindgen(js_namespace = console)]
    pub fn error(s: &str);
}

#[wasm_bindgen]
pub fn greet(name: &str) {
    alert(&format!("Hello, {name}!"));
}

#[wasm_bindgen(start)]
pub fn start() {
    panic::set_hook(Box::new(|panic_info: &PanicHookInfo| {
        error(panic_info.payload().downcast_ref::<String>().unwrap());
        error(panic_info.location().unwrap().to_string().as_str());
    }));
}
