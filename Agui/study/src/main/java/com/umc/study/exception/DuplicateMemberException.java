package com.umc.study.exception;

import lombok.Getter;

@Getter
public class DuplicateMemberException extends RuntimeException {

    private final String code;

    private DuplicateMemberException(String code, String message) {
        super(message);
        this.code = code;
    }

    public static DuplicateMemberException email() {
        return new DuplicateMemberException("MEMBER4091", "이미 사용 중인 이메일입니다.");
    }

    public static DuplicateMemberException nickname() {
        return new DuplicateMemberException("MEMBER4092", "이미 사용 중인 닉네임입니다.");
    }
}
