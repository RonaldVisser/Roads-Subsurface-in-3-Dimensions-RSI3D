library(RPostgres)

#drv <- dbDriver("PostgreSQL")
con <- dbConnect(RPostgres::Postgres(),    
                 host = "localhost",   
                 port = 5432,   
                 dbname = "griffiersveld",   
                 user = "postgres",   
                 password=getPass::getPass() )