// 1. Movie Class 작성
class Movie {
    final String title;
    final double rating;

    Movie({
        required this.title,
        required this.rating,
    });
}

// 2. 영화 3개를 List<Movie>에 넣기.
void main(){
    List<Movie> movies = [
        Movie(title:'인셉션',rating:9.3),
        Movie(title:'파묘', rating:8.2),
        Movie(title:'인터스텔라',rating:9.1),
    ];

    // 3. for 문으로 영화 제목 출력
    for (var movie in movies){
        print(movie.title);
    }

    // 4. nullable 닉네임을 안전한 기본값으로 변환
    String? nickname;
    String safeNickname = nickname ?? '익명의 사용자';

    print('사용자 닉네임 : $safeNickname');
}