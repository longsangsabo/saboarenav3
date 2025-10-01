class TournamentRepository {
  Future<List<TournamentModel>> getTournaments() async {
    // This is mock data. In a real app, you would fetch this from a database or API.
    await Future.delayed(const Duration(seconds: 1));
    return [
      TournamentModel(
        id: '1',
        title: 'Giải đấu Mùa Xuân',
        club: ClubModel(id: 'clb1', name: 'CLB Bida A', location: 'TP.HCM'),
        format: '8-ball',
        entryFee: 50000,
        prizePool: 1000000,
        currentParticipants: 12,
        maxParticipants: 32,
        startDate: DateTime.now().add(const Duration(days: 7)),
        registrationDeadline: DateTime.now().add(const Duration(days: 5)),
        status: 'upcoming',
        coverImageUrl:
            'https://via.placeholder.com/300x200.png?text=Tournament+1',
        hasLiveStream: true,
        skillLevelRequired: 'Mọi trình độ',
      ),
      TournamentModel(
        id: '2',
        title: 'Giải đấu Mùa Hè',
        club: ClubModel(id: 'clb2', name: 'CLB Bida B', location: 'Hà Nội'),
        format: '9-ball',
        entryFee: 0,
        prizePool: 500000,
        currentParticipants: 20,
        maxParticipants: 64,
        startDate: DateTime.now().add(const Duration(days: 14)),
        registrationDeadline: DateTime.now().add(const Duration(days: 10)),
        status: 'upcoming',
        coverImageUrl:
            'https://via.placeholder.com/300x200.png?text=Tournament+2',
        hasLiveStream: false,
        skillLevelRequired: 'Nâng cao',
      ),
      TournamentModel(
        id: '3',
        title: 'Giải đấu Đang Diễn Ra',
        club: ClubModel(id: 'clb3', name: 'CLB Bida C', location: 'Đà Nẵng'),
        format: '10-ball',
        entryFee: 100000,
        prizePool: 2000000,
        currentParticipants: 32,
        maxParticipants: 32,
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        status: 'live',
        coverImageUrl:
            'https://via.placeholder.com/300x200.png?text=Tournament+3',
        hasLiveStream: true,
        skillLevelRequired: 'Chuyên nghiệp',
      ),
      TournamentModel(
        id: '4',
        title: 'Giải đấu Đã Kết Thúc',
        club: ClubModel(id: 'clb4', name: 'CLB Bida D', location: 'Cần Thơ'),
        format: '8-ball',
        entryFee: 20000,
        prizePool: 300000,
        currentParticipants: 16,
        maxParticipants: 16,
        startDate: DateTime.now().subtract(const Duration(days: 10)),
        status: 'completed',
        coverImageUrl:
            'https://via.placeholder.com/300x200.png?text=Tournament+4',
        hasLiveStream: false,
        skillLevelRequired: 'Mọi trình độ',
      ),
    ];
  }
}
