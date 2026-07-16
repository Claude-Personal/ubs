use sha2::{Digest, Sha256};
use std::env;
use std::fs::File;
use std::io::{self, Read};
use std::path::{Component, Path};
use std::process::ExitCode;

fn sha256(path: &Path) -> io::Result<String> {
    let mut file = File::open(path)?;
    let mut hasher = Sha256::new();
    let mut buffer = [0_u8; 64 * 1024];
    loop {
        let read = file.read(&mut buffer)?;
        if read == 0 {
            break;
        }
        hasher.update(&buffer[..read]);
    }
    Ok(format!("{:x}", hasher.finalize()))
}

fn safe_relative(path: &Path) -> bool {
    !path.as_os_str().is_empty()
        && path
            .components()
            .all(|component| matches!(component, Component::Normal(_)))
}

fn usage() {
    eprintln!("Usage: ubs-helper sha256 FILE | verify-sha256 FILE HASH | validate-relative PATH");
}

fn run(arguments: &[String]) -> Result<(), String> {
    match arguments {
        [command, path] if command == "sha256" => {
            println!(
                "{}",
                sha256(Path::new(path)).map_err(|error| error.to_string())?
            );
            Ok(())
        }
        [command, path, expected] if command == "verify-sha256" => {
            if expected.len() != 64 || !expected.bytes().all(|value| value.is_ascii_hexdigit()) {
                return Err("expected hash must be 64 hexadecimal characters".into());
            }
            let actual = sha256(Path::new(path)).map_err(|error| error.to_string())?;
            if actual.eq_ignore_ascii_case(expected) {
                Ok(())
            } else {
                Err(format!(
                    "SHA-256 mismatch: expected={expected} actual={actual}"
                ))
            }
        }
        [command, path] if command == "validate-relative" => {
            if safe_relative(Path::new(path)) {
                Ok(())
            } else {
                Err("path must contain only normal relative components".into())
            }
        }
        _ => {
            usage();
            Err("invalid arguments".into())
        }
    }
}

fn main() -> ExitCode {
    let arguments: Vec<String> = env::args().skip(1).collect();
    match run(&arguments) {
        Ok(()) => ExitCode::SUCCESS,
        Err(error) => {
            eprintln!("{error}");
            ExitCode::FAILURE
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::fs;
    use std::time::{SystemTime, UNIX_EPOCH};

    #[test]
    fn hashes_known_content() {
        let unique = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap()
            .as_nanos();
        let path = env::temp_dir().join(format!("ubs-helper-{unique}.txt"));
        fs::write(&path, b"abc").unwrap();
        assert_eq!(
            sha256(&path).unwrap(),
            "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad",
        );
        fs::remove_file(path).unwrap();
    }

    #[test]
    fn rejects_unsafe_relative_paths() {
        assert!(safe_relative(Path::new("scripts/ubs.py")));
        assert!(!safe_relative(Path::new("../escape")));
        assert!(!safe_relative(Path::new("/absolute")));
        assert!(safe_relative(Path::new("a/./b")));
    }
}
