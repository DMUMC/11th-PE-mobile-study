package com.umc.study.service;

import java.util.List;
import java.util.Map;

import com.umc.study.repository.BookRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class BookService {

    private final BookRepository bookRepository;

    public List<Map<String, Object>> getBooksByCategory(Long categoryId) {
        return bookRepository.findByCategoryId(categoryId);
    }
}
