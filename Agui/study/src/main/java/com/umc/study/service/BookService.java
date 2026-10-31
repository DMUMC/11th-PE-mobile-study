package com.umc.study.service;

import java.util.List;
import java.util.Map;

import com.umc.study.dto.BookResponse;
import com.umc.study.repository.BookRepository;
import com.umc.study.repository.JdbcBookRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class BookService {

    private final BookRepository bookRepository;
    private final JdbcBookRepository jdbcBookRepository;

    @Transactional(readOnly = true)
    public List<BookResponse> getBooks() {
        return bookRepository.findAllByOrderByBookIdDesc().stream()
                .map(BookResponse::from)
                .toList();
    }

    public List<Map<String, Object>> getBooksByCategory(Long categoryId) {
        return jdbcBookRepository.findByCategoryId(categoryId);
    }
}
