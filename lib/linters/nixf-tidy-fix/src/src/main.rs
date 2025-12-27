use {
    serde::{self, Deserialize},
    serde_repr::Deserialize_repr,
    std::{
        collections::HashSet,
        env,
        ffi::OsString,
        fmt,
        fs::File,
        io::{self, BufReader, Read, Seek, Write},
        process::{Command, ExitCode, Stdio},
    },
};

fn main() -> ExitCode {
    let mut args = env::args_os();
    args.next();

    let config_path = args.next().unwrap();
    let config = Config::read_from_path(&config_path).unwrap();

    let file_path = args.next().unwrap();
    let mut file = File::options()
        .read(true)
        .write(true)
        .open(&file_path)
        .unwrap();

    let mut file_contents = String::new();
    file.read_to_string(&mut file_contents).unwrap();

    let mut nixf_tidy_command = Command::new("nixf-tidy");
    if config.variable_lookup {
        nixf_tidy_command.arg("--variable-lookup");
    }

    let mut nixf_tidy = nixf_tidy_command
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .spawn()
        .unwrap();

    nixf_tidy
        .stdin
        .as_mut()
        .unwrap()
        .write_all(file_contents.as_bytes())
        .unwrap();

    let output = nixf_tidy.wait_with_output().unwrap();
    if !output.status.success() {
        return ExitCode::FAILURE;
    }

    let diagnostics: Vec<Diagnostic> = serde_json::from_slice(&output.stdout).unwrap();
    let mut exit_code = ExitCode::SUCCESS;
    let mut text_edit = ra_ap_text_edit::TextEditBuilder::default();
    for diagnostic in diagnostics {
        if !config.suppress.contains(&diagnostic.sname) {
            if diagnostic.fixes.is_empty() {
                eprintln!("{}:{}", file_path.display(), diagnostic);
                exit_code = ExitCode::FAILURE;
            } else {
                diagnostic.fix(&mut text_edit);
            }
        }
    }

    if !text_edit.is_empty() {
        let text_edit = text_edit.finish();
        text_edit.apply(&mut file_contents);
        file.set_len(0).unwrap();
        file.rewind().unwrap();
        file.write_all(file_contents.as_bytes()).unwrap();
    }

    exit_code
}

#[derive(Deserialize)]
#[serde(rename_all = "kebab-case")]
struct Config {
    #[serde(default)]
    variable_lookup: bool,
    #[serde(default)]
    suppress: HashSet<String>,
}

impl Config {
    fn read_from_path(path: &OsString) -> Result<Self, io::Error> {
        let file = File::open(path).unwrap();
        let reader = BufReader::new(file);
        Ok(serde_json::from_reader(reader)?)
    }
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
struct Diagnostic {
    #[serde(flatten)]
    partial: PartialDiagnostic,
    // kind: i32,
    sname: String,
    severity: Severity,
    message: String,
    notes: Vec<Note>,
    fixes: Vec<Fix>,
}

impl Diagnostic {
    fn fix(self, text_edit: &mut ra_ap_text_edit::TextEditBuilder) {
        for fix in self.fixes {
            fix.apply(text_edit);
        }
    }
}

impl fmt::Display for Diagnostic {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        write!(
            f,
            "{}:{}: {}: {} [{}]",
            self.partial.range.l_cur.line + 1,
            self.partial.range.l_cur.column + 1,
            self.severity,
            dyn_fmt::Arguments::new(&self.message, &self.partial.args),
            self.sname
        )?;

        for note in &self.notes {
            write!(f, "\n{}", note)?;
        }

        Ok(())
    }
}

#[derive(Deserialize_repr)]
#[repr(i32)]
enum Severity {
    Fatal,
    Error,
    Warning,
    Info,
    Hint,
}

impl fmt::Display for Severity {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        write!(
            f,
            "{}",
            match self {
                Severity::Fatal => "fatal",
                Severity::Error => "error",
                Severity::Warning => "warning",
                Severity::Info => "info",
                Severity::Hint => "hint",
            }
        )
    }
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
struct Note {
    #[serde(flatten)]
    partial: PartialDiagnostic,
    // kind: i32,
    sname: String,
    message: String,
}

impl fmt::Display for Note {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        write!(
            f,
            "{}:{}: note: {} [{}]",
            self.partial.range.l_cur.line + 1,
            self.partial.range.l_cur.column + 1,
            dyn_fmt::Arguments::new(&self.message, &self.partial.args),
            self.sname
        )
    }
}

#[derive(Deserialize)]
struct PartialDiagnostic {
    args: Vec<String>,
    range: LexerCursorRange,
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
struct Fix {
    edits: Vec<TextEdit>,
    // message: String,
}

impl Fix {
    fn apply(self, text_edit: &mut ra_ap_text_edit::TextEditBuilder) {
        for edit in self.edits {
            edit.apply(text_edit);
        }
    }
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
struct TextEdit {
    #[serde(rename = "range")]
    old_range: LexerCursorRange,
    new_text: String,
}

impl TextEdit {
    fn apply(self, text_edit: &mut ra_ap_text_edit::TextEditBuilder) {
        text_edit.replace(self.old_range.into(), self.new_text);
    }
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
struct LexerCursorRange {
    l_cur: LexerCursor,
    r_cur: LexerCursor,
}

impl From<LexerCursorRange> for ra_ap_text_edit::TextRange {
    fn from(range: LexerCursorRange) -> Self {
        Self::new(range.l_cur.into(), range.r_cur.into())
    }
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
struct LexerCursor {
    line: u64,
    column: u64,
    offset: usize,
}

impl From<LexerCursor> for ra_ap_text_edit::TextSize {
    fn from(cursor: LexerCursor) -> Self {
        Self::new(cursor.offset.try_into().unwrap())
    }
}
