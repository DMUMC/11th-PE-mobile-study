package com.umc.movie.config;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.Operation;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.media.Content;
import io.swagger.v3.oas.models.media.MediaType;
import io.swagger.v3.oas.models.responses.ApiResponse;
import io.swagger.v3.oas.models.responses.ApiResponses;
import io.swagger.v3.oas.models.security.SecurityRequirement;
import io.swagger.v3.oas.models.security.SecurityScheme;
import org.springdoc.core.customizers.OpenApiCustomizer;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class OpenApiConfig {

    @Bean
    OpenAPI movieOpenApi() {
        return new OpenAPI()
                .info(new Info().title("Movie API - 8주차").version("1.0")
                        .description("로그인은 공개 API입니다. 즐겨찾기와 영화 기록에는 Bearer 토큰이 필요합니다."))
                .schemaRequirement("bearerAuth", new SecurityScheme()
                        .type(SecurityScheme.Type.HTTP).scheme("bearer").bearerFormat("JWT"));
    }

    @Bean
    OpenApiCustomizer weekEightDocumentation(ObjectMapper mapper) {
        return openApi -> {
            var paths = openApi.getPaths();
            document(paths.get("/favorites").getPost(), "즐겨찾기 등록", "201",
                    "{\"isSuccess\":true,\"code\":\"COMMON201\",\"message\":\"즐겨찾기를 등록했습니다.\",\"result\":{\"favoriteId\":1,\"movieId\":550,\"createdAt\":\"2026-09-06T21:00:00\"}}", mapper,
                    "400|COMMON4001|영화 ID는 양수여야 합니다.", "404|MEMBER404_1|해당 회원을 찾을 수 없습니다.", "409|FAVORITE409_1|이미 이 영화를 즐겨찾기하셨습니다.");
            document(paths.get("/favorites").getGet(), "내 즐겨찾기 목록 조회", "200",
                    "{\"isSuccess\":true,\"code\":\"COMMON200\",\"message\":\"내 즐겨찾기 목록을 조회했습니다.\",\"result\":[{\"favoriteId\":1,\"movieId\":550,\"createdAt\":\"2026-09-06T21:00:00\"}]}", mapper);
            document(paths.get("/favorites/{movieId}").getGet(), "즐겨찾기 여부 조회", "200",
                    "{\"isSuccess\":true,\"code\":\"COMMON200\",\"message\":\"즐겨찾기 여부를 조회했습니다.\",\"result\":{\"isFavorite\":true}}", mapper);
            document(paths.get("/favorites/{movieId}").getDelete(), "즐겨찾기 해제", "200",
                    "{\"isSuccess\":true,\"code\":\"COMMON200\",\"message\":\"즐겨찾기를 해제했습니다.\",\"result\":null}", mapper,
                    "404|FAVORITE404_1|즐겨찾기한 영화를 찾을 수 없습니다.");
            document(paths.get("/movie-records").getPost(), "평점과 즐겨찾기 함께 저장", "201",
                    "{\"isSuccess\":true,\"code\":\"COMMON201\",\"message\":\"영화 기록을 저장했습니다.\",\"result\":{\"rating\":{\"ratingId\":1,\"movieId\":238,\"score\":5,\"comment\":\"다시 보고 싶은 영화입니다.\",\"createdAt\":\"2026-09-06T21:10:00\",\"updatedAt\":\"2026-09-06T21:10:00\"},\"favorite\":{\"favoriteId\":2,\"movieId\":238,\"createdAt\":\"2026-09-06T21:10:00\"}}}", mapper,
                    "400|COMMON4001|영화 ID는 양수여야 합니다.", "404|MEMBER404_1|해당 회원을 찾을 수 없습니다.", "409|RATING409_1|이미 이 영화에 평점을 남기셨습니다.", "409|FAVORITE409_1|이미 이 영화를 즐겨찾기하셨습니다.");
            paths.get("/auth/login").getPost().summary("로그인 (공개 API)");
        };
    }

    private void document(Operation operation, String summary, String successStatus, String success,
                          ObjectMapper mapper, String... errors) {
        operation.summary(summary).addSecurityItem(new SecurityRequirement().addList("bearerAuth"));
        ApiResponses responses = new ApiResponses();
        responses.addApiResponse(successStatus, response("성공", success, mapper));
        addError(responses, mapper, "401|AUTH401_2|로그인이 필요한 요청입니다.");
        for (String error : errors) {
            addError(responses, mapper, error);
        }
        operation.setResponses(responses);
    }

    private void addError(ApiResponses responses, ObjectMapper mapper, String error) {
        String[] fields = error.split("\\|", 3);
        String json = "{\"isSuccess\":false,\"code\":\"" + fields[1]
                + "\",\"message\":\"" + fields[2] + "\",\"result\":null}";
        ApiResponse response = responses.computeIfAbsent(fields[0], key ->
                new ApiResponse().description("실패 코드 예시").content(new Content()
                        .addMediaType("application/json", new MediaType())));
        try {
            response.getContent().get("application/json").addExamples(fields[1],
                    new io.swagger.v3.oas.models.examples.Example().value(mapper.readValue(json, Object.class)));
        } catch (JsonProcessingException e) {
            throw new IllegalStateException("API 응답 예시를 생성하지 못했습니다.", e);
        }
    }

    private ApiResponse response(String description, String json, ObjectMapper mapper) {
        try {
            return new ApiResponse().description(description).content(new Content()
                    .addMediaType("application/json", new MediaType().example(mapper.readValue(json, Object.class))));
        } catch (JsonProcessingException e) {
            throw new IllegalStateException("API 응답 예시를 생성하지 못했습니다.", e);
        }
    }
}
