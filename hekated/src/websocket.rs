use actix::{Actor, StreamHandler};
use actix_web::{get, web, Error, HttpRequest, HttpResponse};
use actix_web_actors::ws;
use serde::{Deserialize, Serialize};

/// Define HTTP actor
struct MyWs;

impl Actor for MyWs {
    type Context = ws::WebsocketContext<Self>;
}

#[derive(Debug, Deserialize)]
#[serde(untagged)]
enum RequestMsg {
    Tag(String),
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "kebab-case")]
enum ResponseMsg {
    Pong,
    Error(String),
}

/// Handler for ws::Message message
impl StreamHandler<Result<ws::Message, ws::ProtocolError>> for MyWs {
    fn handle(&mut self, msg: Result<ws::Message, ws::ProtocolError>, ctx: &mut Self::Context) {
        match dbg!(msg) {
            Ok(ws::Message::Ping(msg)) => ctx.pong(&msg),
            Ok(ws::Message::Text(text)) => {
                let res = match dbg!(serde_json::from_str::<RequestMsg>(&text)) {
                    Ok(RequestMsg::Tag(tag)) => match tag.as_str() {
                        "ping" => ResponseMsg::Pong,
                        _ => ResponseMsg::Error("unknown request tag".to_owned()),
                    },
                    Err(_) => ResponseMsg::Error("invalid request format".to_owned()),
                };

                ctx.text(serde_json::to_string(&res).unwrap());
            }
            _ => (),
        }
    }
}

#[get("/ws")]
async fn service(req: HttpRequest, stream: web::Payload) -> Result<HttpResponse, Error> {
    ws::start(MyWs, &req, stream)
}
