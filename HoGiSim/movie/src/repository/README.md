# Repository 등록

워크북 지침에 따라 별도 Repository 클래스를 만들지 않습니다.
app.module.ts의 TypeOrmModule.forFeature([Member, Rating])에서 등록하고
각 Service에 Repository<Entity>를 주입합니다.
