use sha2::{Digest, Sha256};
use std::collections::HashMap;
use std::env;
use std::fs::{self, File};
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

fn manifest_entries(path: &Path) -> Result<Vec<(String, String)>, String> {
    let text = fs::read_to_string(path).map_err(|error| error.to_string())?;
    let mut entries = Vec::new();
    for (index, line) in text.lines().enumerate() {
        let fields: Vec<&str> = line.split_whitespace().collect();
        if fields.is_empty() || fields[0].starts_with('#') || fields[0] == "version" {
            continue;
        }
        if fields.len() != 3 || fields[0] != "file" {
            return Err(format!("invalid manifest line {}", index + 1));
        }
        let hash = fields[1];
        let relative = fields[2];
        if hash.len() != 64 || !hash.bytes().all(|value| value.is_ascii_hexdigit()) {
            return Err(format!("invalid SHA-256 on manifest line {}", index + 1));
        }
        if !safe_relative(Path::new(relative)) {
            return Err(format!("unsafe path on manifest line {}", index + 1));
        }
        entries.push((relative.to_owned(), hash.to_ascii_lowercase()));
    }
    Ok(entries)
}

fn verify_manifest(manifest: &Path, root: &Path, selected: &[String]) -> Result<(), String> {
    let entries = manifest_entries(manifest)?;
    let expected: HashMap<&str, &str> = entries
        .iter()
        .map(|(relative, hash)| (relative.as_str(), hash.as_str()))
        .collect();
    let paths: Vec<&str> = if selected.is_empty() {
        entries
            .iter()
            .map(|(relative, _)| relative.as_str())
            .collect()
    } else {
        selected.iter().map(String::as_str).collect()
    };
    for relative in paths {
        if !safe_relative(Path::new(relative)) {
            return Err(format!("unsafe relative path: {relative}"));
        }
        let hash = expected
            .get(relative)
            .ok_or_else(|| format!("path is not present in manifest: {relative}"))?;
        let actual = sha256(&root.join(relative)).map_err(|error| error.to_string())?;
        if !actual.eq_ignore_ascii_case(hash) {
            return Err(format!(
                "SHA-256 mismatch: path={relative} expected={hash} actual={actual}"
            ));
        }
    }
    Ok(())
}

fn changed_manifest(manifest: &Path, root: &Path) -> Result<(), String> {
    for (relative, expected) in manifest_entries(manifest)? {
        let target = root.join(&relative);
        let changed = match sha256(&target) {
            Ok(actual) => !actual.eq_ignore_ascii_case(&expected),
            Err(error) if error.kind() == io::ErrorKind::NotFound => true,
            Err(error) => return Err(error.to_string()),
        };
        if changed {
            println!("{relative}");
        }
    }
    Ok(())
}

fn usage() {
    eprintln!(
        "Usage: ubs-helper sha256 FILE | verify-sha256 FILE HASH | validate-relative PATH | \
         changed-manifest MANIFEST ROOT | verify-manifest MANIFEST ROOT [PATH ...]"
    );
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
        [command, manifest, root] if command == "changed-manifest" => {
            changed_manifest(Path::new(manifest), Path::new(root))
        }
        [command, manifest, root, selected @ ..] if command == "verify-manifest" => {
            verify_manifest(Path::new(manifest), Path::new(root), selected)
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

    #[test]
    fn compares_and_verifies_manifest_in_one_process() {
        let unique = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap()
            .as_nanos();
        let root = env::temp_dir().join(format!("ubs-helper-manifest-{unique}"));
        fs::create_dir_all(root.join("scripts")).unwrap();
        fs::write(root.join("scripts/ubs.py"), b"abc").unwrap();
        let manifest = root.join("manifest.txt");
        fs::write(
            &manifest,
            "version 3.1.0\nfile ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad scripts/ubs.py\n",
        )
        .unwrap();
        verify_manifest(&manifest, &root, &[]).unwrap();
        fs::write(root.join("scripts/ubs.py"), b"changed").unwrap();
        assert!(verify_manifest(&manifest, &root, &[]).is_err());
        fs::remove_dir_all(root).unwrap();
    }
}
