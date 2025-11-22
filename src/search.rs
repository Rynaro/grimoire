pub struct Search {
    pub query: String,
    pub results: Vec<usize>,
}

impl Search {
    pub fn new() -> Self {
        Self {
            query: String::new(),
            results: Vec::new(),
        }
    }

    pub fn reset(&mut self) {
        self.query.clear();
        self.results.clear();
    }
}
