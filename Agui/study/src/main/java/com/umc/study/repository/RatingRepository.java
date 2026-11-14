package com.umc.study.repository;

import com.umc.study.entity.Rating;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface RatingRepository extends JpaRepository<Rating, Long> {
    List<Rating> findByMember_MemberIdOrderByRatingIdDesc(Long memberId);
    boolean existsByMember_MemberIdAndMovieId(Long memberId, Long movieId);
}
