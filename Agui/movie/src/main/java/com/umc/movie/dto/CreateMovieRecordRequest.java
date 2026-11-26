package com.umc.movie.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import io.swagger.v3.oas.annotations.media.Schema;

public record CreateMovieRecordRequest(
        @NotNull(message = "영화 ID는 필수입니다.")
        @Positive(message = "영화 ID는 양수여야 합니다.")
        @Schema(description = "TMDB 영화 ID", example = "238") Long movieId,

        @NotNull(message = "별점은 필수입니다.")
        @Min(value = 1, message = "별점은 1점 이상이어야 합니다.")
        @Max(value = 5, message = "별점은 5점 이하여야 합니다.")
        @Schema(description = "별점 (1~5)", example = "5") Integer score,

        @Schema(description = "영화 후기", example = "다시 보고 싶은 영화입니다.") String comment,

        @NotNull(message = "즐겨찾기 추가 여부는 필수입니다.")
        @Schema(description = "즐겨찾기 동시 저장 여부", example = "true") Boolean addToFavorites
) {
}
