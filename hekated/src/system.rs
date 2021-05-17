use actix_web::{get, web, Error, HttpResponse, Scope};
use serde::Serialize;
use std::{fs, process::Command};

pub fn service() -> Scope {
    web::scope("/system").service(info)
}

#[derive(Serialize, Debug)]
struct InfoResponse {
    current_load: f32,
    memory_info: InfoResMemory,
    disk_usage: Vec<InfoResDisk>,
}

#[derive(Serialize, Debug)]
struct InfoResMemory {
    phys_total: u64,
    phys_used: u64,
    phys_shared: u64,
    phys_cache: u64,
    swap_total: u64,
    swap_used: u64,
}

#[derive(Serialize, Debug)]
struct InfoResDisk {
    device: String,
    total: u64,
    used: u64,
}

macro_rules! cmd {
    ($cmd:expr $(, $arg:expr),* $(,)?) => {
        Command::new($cmd)
        $(.arg($arg))*
        .output()
    };
}

#[get("/info")]
async fn info() -> Result<HttpResponse, Error> {
    let current_load = fs::read_to_string("/proc/loadavg")?
        .split_ascii_whitespace()
        .next()
        .and_then(|f| f.parse().ok())
        .unwrap_or(-1.0);

    let num_cpus = fs::read_to_string("/proc/cpuinfo")?
        .lines()
        .filter(|line| line.starts_with("processor\t"))
        .count();

    let current_load = current_load / num_cpus as f32;

    let free = cmd!("free", "-k")?.stdout;
    let free = String::from_utf8_lossy(&free)
        .lines()
        .skip(1)
        .map(|mem| {
            mem.split_ascii_whitespace()
                .skip(1)
                .map(|n| n.parse().unwrap_or(u64::MAX))
                .collect()
        })
        .collect::<Vec<Vec<u64>>>();

    let memory_info = InfoResMemory {
        phys_total: free[0][0],
        phys_used: free[0][1],
        phys_shared: free[0][3],
        phys_cache: free[0][4],
        swap_total: free[1][0],
        swap_used: free[1][1],
    };

    let df = cmd!("df", "-k")?.stdout;
    let disk_usage = String::from_utf8_lossy(&df)
        .lines()
        .skip(1)
        .filter_map(|line| {
            let fields = line.split_ascii_whitespace().collect::<Vec<&str>>();
            if !fields[0].starts_with("/dev/") {
                None
            }
            else {
                Some(InfoResDisk {
                    total: fields[1].parse().unwrap_or(u64::MAX),
                    used: fields[2].parse().unwrap_or(0),
                    device: fields[5].to_owned(),
                })
            }
        })
        .collect();

    Ok(HttpResponse::Ok().json(InfoResponse {
        current_load,
        memory_info,
        disk_usage,
    }))
}
