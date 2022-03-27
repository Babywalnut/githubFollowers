# githubFollowers

github 사용자를 검색하고 사용자의 follower들을 collectionView로 보여주는 간단한 앱이에요.

## 구현 내용
### [Feat.SearchVC, Custom Alert](https://github.com/Babywalnut/githubFollowers/tree/feat/SearchVC%2CCustom_Alert)
- SearchViewController를 통하여 Github을 사용중인 User의 닉네임을 입력 받아옵니다.
- TextField에 입력된 값이 존재하 경우 text를 FollowerListViewController로 전달합니다.
- 입력된 값이 없을시 GitHubFollwersAlertViewController(CustomAlert)를 push하여 화면에 출력합니다.

### [Feat.Networking](https://github.com/Babywalnut/githubFollowers/tree/feat/Networking)
- 앱에서 사용할 데이터를 Github API로부터 JSON형태로 받아옵니다.
- URLSession을 활용하여 API와 http통신(GET)을 합니다.
- http통신을 진행할 때 API로 부터 전달받은 데이터, Response, 에러에 대한 처리를 해줍니다.

### [Feat.CollectionView](https://github.com/Babywalnut/githubFollowers/tree/feat/CollectionView)
- FollowerListView Controller에 CollectionView를 활용하여 입력한 user에 대한 follower 계정 정보를 출력합니다.(follower 없을시 예외처리)
- 받아온 follower 데이터 중 avatarURL을 활용하여 이미지를 받아오고 이미지에 대한 캐싱처리를 합니다.
- SearchBar를 통하여 출력된 follower 정보를 filtering하여 보여줍니다.
