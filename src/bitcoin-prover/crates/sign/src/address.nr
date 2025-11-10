pub struct Address {
    version: u8,
}

impl Address {
    pub fn new_p2pk() -> Self {
        Self { version: 0x00 }
    }

    pub fn is_p2pk(self) -> bool {
        self.version == 0x00
    }

    pub fn new_p2pkh() -> Self {
        Self { version: 0x01 }
    }

    pub fn is_p2pkh(self) -> bool {
        self.version == 0x01
    }

    pub fn new_p2sh() -> Self {
        Self { version: 0x02 }
    }

    pub fn is_p2sh(self) -> bool {
        self.version == 0x02
    }

    pub fn new_p2ms() -> Self {
        Self { version: 0x03 }
    }

    pub fn is_p2ms(self) -> bool {
        self.version == 0x03
    }

    pub fn new_p2wpkh() -> Self {
        Self { version: 0x04 }
    }

    pub fn is_p2wpkh(self) -> bool {
        self.version == 0x04
    }

    pub fn new_p2wsh() -> Self {
        Self { version: 0x05 }
    }

    pub fn is_p2wsh(self) -> bool {
        self.version == 0x05
    }

    pub fn new_p2tr() -> Self {
        Self { version: 0x06 }
    }

    pub fn is_p2tr(self) -> bool {
        self.version == 0x06
    }

    pub fn new_script_sig() -> Self {
        Self { version: 0x07 }
    }

    pub fn is_script_sig(self) -> bool {
        self.version == 0x07
    }
}
