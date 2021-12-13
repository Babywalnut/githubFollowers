# githubFollowers - Feat.SearchVC, Custom Alert

## 📕작업 배경
- SearchViewController를 통하여 Github을 사용중인 User의 닉네임을 입력 받아야 합니다.
- TextField에 입력된 값이 존재하 경우 text를 FollowerListViewController로 전달해야 합니다.
- 입력된 값이 없을시 GitHubFollwersAlertViewController(CustomAlert)를 push하여 화면에 출력시켜야 합니다. 

## 🔨구현 내용
- [RootViewController로 사용될 TabBarController 구현 -> SceneDelegate.swift](#rootviewcontroller-설정)
- [SearchViewController UI 구현](#searchviewcontroller-ui-구현)
- [GitHubFollwersAlertViewController UI 구현](#custom-alert-ui-구현)
- [SearchViewController -> FollwerListViewController 데이터 전달 및 예외처리](#데이터전달-및-예외처리)

### RootViewController 설정


<img width="676" alt="스크린샷 2021-12-13 오후 2 15 00" src="https://user-images.githubusercontent.com/56648865/145756471-3576dfc7-da92-45cd-994e-6efa37dd33e7.png">

- TabBarController와 NavigationController를 설정해주는 swift파일을 따로 생성해주지 않고 SceneSession을 설정해주는 SceneDelegate 내에서 메서드의 반환값으로 인스턴스를 바로 생성하여  RootViewController에 할당하였습니다.
- 앱 내의 모드 TabBar와 NavigationBar의 tintColor를 통일시켰습니다.

### SearchViewController UI 구현

<img width="850" alt="스크린샷 2021-12-13 오후 3 54 09" src="https://user-images.githubusercontent.com/56648865/145766792-9de62830-bed0-444b-a314-f11010029adb.png">


- custom TextField, custom Button 사용
- 항상 view가 나타날 때마다 SearchViewController의 NavigationBar를 가려주기 위하여 viewWillAppear()에서 설정




### Custom Alert UI 구현

<img width="850" alt="스크린샷 2021-12-13 오후 5 32 25" src="https://user-images.githubusercontent.com/56648865/145778408-5695b2c3-b6ce-49e2-8a6b-8ea12aed602d.png">

- containerView를 생성하여 Alert 생성
- background의 투명도를 조절하여 .overFullScreen으로 present하지만 containerView 영역만 전달내용 출력

### 데이터전달 및 예외처리

<img width="789" alt="스크린샷 2021-12-13 오후 6 58 50" src="https://user-images.githubusercontent.com/56648865/145791295-5ac6bff0-0e77-4e73-9554-956becb49d37.png">

- TextField의 text를 FollwerListViewController의 title로 전달
- View Hierarchy 상으로 하위에 존재하는 SearchViewController에서 FollwerListViewController로 데이터를 전달하는 것이기 때문에 직접전달로 구현
- TextField의 text가 입력되지 않을 경우 custom Alert 출력


## 📝학습 내용

- navigationController?.isNavgationHidden은 현재 viewController가 포함된 navigationController의 모든 viewController에 적용된다.
- Delegate Pattern을 통하여 데이터를 전달할 시에는 데이터를 받는 인스턴스가 delegate로 선언되기 이전에는 데이터를 전달할 수 없다.
