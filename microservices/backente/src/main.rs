use actix_web::{get, App, HttpResponse, HttpServer, Responder};
use actix_cors::Cors;

#[get("/")]
async fn hello() -> impl Responder {
    HttpResponse::Ok().body("Hello world from Rust backente!")
}

#[get("/health")]
async fn health_check() -> impl Responder {
    HttpResponse::Ok().body("Backente is up and running!")
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    HttpServer::new(|| {
        App::new()
            .wrap(Cors::permissive())
            .service(hello)
            .service(health_check)
    })
    .bind("0.0.0.0:8080")?
    .run()
    .await
}