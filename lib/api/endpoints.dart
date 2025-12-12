/// API 端点定义
class Endpoints {
  // ================ 搜索相关 ================

  /// 搜索歌曲/专辑/歌手/歌单
  /// type: 1=单曲, 10=专辑, 100=歌手, 1000=歌单
  static const String search = '/cloudsearch';

  /// 搜索建议
  static const String searchSuggest = '/search/suggest';

  /// 热门搜索
  static const String searchHot = '/search/hot/detail';

  // ================ 歌曲相关 ================

  /// 获取歌曲详情
  static const String songDetail = '/song/detail';

  /// 获取歌曲 URL
  static const String songUrl = '/song/url/v1';

  /// 获取歌词
  static const String lyric = '/lyric';

  // ================ 专辑相关 ================

  /// 获取专辑详情
  static const String albumDetail = '/album';

  /// 最新专辑
  static const String albumNewest = '/album/newest';

  // ================ 歌手相关 ================

  /// 歌手详情
  static const String artistDetail = '/artist/detail';

  /// 歌手热门歌曲
  static const String artistTopSongs = '/artist/top/song';

  /// 歌手专辑
  static const String artistAlbums = '/artist/album';

  // ================ 歌单相关 ================

  /// 获取歌单详情
  static const String playlistDetail = '/playlist/detail';

  /// 推荐歌单
  static const String recommendPlaylists = '/personalized';

  /// 热门歌单分类
  static const String playlistCatlist = '/playlist/catlist';

  /// 精品歌单
  static const String topPlaylist = '/top/playlist';

  // ================ 排行榜 ================

  /// 所有排行榜
  static const String toplist = '/toplist';

  /// 排行榜详情
  static const String toplistDetail = '/toplist/detail';

  // ================ 推荐 ================

  /// 每日推荐歌曲
  static const String recommendSongs = '/recommend/songs';

  /// 推荐新歌
  static const String personalizedNewSongs = '/personalized/newsong';

  /// Banner
  static const String banner = '/banner';

  // ================ 用户相关 ================

  /// 手机号登录
  static const String loginCellphone = '/login/cellphone';

  /// 二维码 Key
  static const String loginQrKey = '/login/qr/key';

  /// 二维码创建
  static const String loginQrCreate = '/login/qr/create';

  /// 二维码检查
  static const String loginQrCheck = '/login/qr/check';

  /// 登录状态
  static const String loginStatus = '/login/status';

  /// 用户详情
  static const String userDetail = '/user/detail';

  /// 用户歌单
  static const String userPlaylist = '/user/playlist';

  /// 喜欢列表
  static const String likelist = '/likelist';

  /// 喜欢歌曲
  static const String like = '/like';

  // ================ 评论 ================

  /// 歌曲评论
  static const String commentMusic = '/comment/music';

  /// 热门评论
  static const String commentHot = '/comment/hot';
}
