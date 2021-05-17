#![feature(async_closure)]

use actix_web::{get, middleware, App, Error, HttpResponse, HttpServer};
use actix_web_httpauth::{
    extractors::AuthenticationError, headers::www_authenticate::bearer::BearerBuilder,
    middleware::HttpAuthentication,
};
use std::{env, fs, path::PathBuf};

mod system;
mod websocket;

#[get("/ping")]
async fn ping() -> Result<HttpResponse, Error> {
    Ok(HttpResponse::Ok().finish())
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    pretty_env_logger::init();

    HttpServer::new(move || {
        App::new()
            // middleware
            .wrap(middleware::Logger::default())
            .wrap(HttpAuthentication::basic(async move |req, creds| {
                // require auth for *all* requests
                let auth_token = fs::read_to_string(
                    PathBuf::from(env::var_os("HOME").expect("$HOME not set"))
                        .join(".hekate-token"),
                )?;

                if creds
                    .password()
                    .map(|s| s.trim_end() == auth_token.trim_end())
                    .unwrap_or(false)
                {
                    Ok(req)
                }
                else {
                    Err(AuthenticationError::new(BearerBuilder::default().finish()).into())
                }
            }))
            // services
            .service(ping)
            .service(system::service())
            .service(websocket::service)
    })
    .keep_alive(actix_http::KeepAlive::Timeout(60))
    .bind(
        env::args()
            .nth(1)
            .expect("please pass listen address:port as first argument"),
    )?
    .run()
    .await
}
