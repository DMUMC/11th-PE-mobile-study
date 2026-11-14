package com.umc.study.controller;

import com.umc.study.dto.ApiResponse;
import com.umc.study.exception.DuplicateMemberException;
import org.hibernate.exception.ConstraintViolationException;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.server.ResponseStatusException;

@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ApiResponse<Void>> handleValidation(MethodArgumentNotValidException exception) {
        String message = exception.getBindingResult().getFieldErrors().get(0).getDefaultMessage();
        return ResponseEntity.badRequest().body(ApiResponse.failure("COMMON4001", message));
    }

    @ExceptionHandler(DataIntegrityViolationException.class)
    public ResponseEntity<ApiResponse<Void>> handleDataIntegrity(DataIntegrityViolationException exception) {
        // MySQL의 자동 UNIQUE 이름(email/nickname)과 명시적으로 지정한 이름을 지원합니다.
        // 사전 중복 검사를 동시에 통과한 요청도 같은 회원 오류로 응답합니다.
        for (Throwable cause = exception; cause != null; cause = cause.getCause()) {
            if (cause instanceof ConstraintViolationException violation
                    && violation.getConstraintName() != null) {
                String key = violation.getConstraintName()
                        .replace("`", "").replace("'", "").replace("\"", "");
                key = key.substring(key.lastIndexOf('.') + 1);

                if (key.equalsIgnoreCase("email") || key.equalsIgnoreCase("uk_member_email")) {
                    return handleDuplicateMember(DuplicateMemberException.email());
                }
                if (key.equalsIgnoreCase("nickname") || key.equalsIgnoreCase("uk_member_nickname")) {
                    return handleDuplicateMember(DuplicateMemberException.nickname());
                }
            }
        }
        return ResponseEntity.status(409)
                .body(ApiResponse.failure("COMMON4091", "이미 존재하는 데이터입니다."));
    }

    @ExceptionHandler(DuplicateMemberException.class)
    public ResponseEntity<ApiResponse<Void>> handleDuplicateMember(DuplicateMemberException exception) {
        return ResponseEntity.status(409)
                .body(ApiResponse.failure(exception.getCode(), exception.getMessage()));
    }

    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<ApiResponse<Void>> handleIllegalArgument(IllegalArgumentException exception) {
        return ResponseEntity.status(409)
                .body(ApiResponse.failure("COMMON4092", exception.getMessage()));
    }

    @ExceptionHandler(ResponseStatusException.class)
    public ResponseEntity<ApiResponse<Void>> handleResponseStatus(ResponseStatusException exception) {
        int status = exception.getStatusCode().value();
        return ResponseEntity.status(status)
                .body(ApiResponse.failure("COMMON" + status, exception.getReason()));
    }
}
