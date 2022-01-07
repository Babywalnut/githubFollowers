# githubFollowers - Feat.CollectionView

## 📕작업 배경
- FollowerListView Controller에 CollectionView를 활용하여 입력한 user에 대한 follower 계정 정보를 출력합니다.(follower 없을시 예외처리)
- 받아온 follower 데이터 중 avatarURL을 활용하여 이미지를 받아오고 이미지에 대한 캐싱처리를 합니다.
- SearchBar를 통하여 출력된 follower 정보를 filtering하여 보여줍니다.

## 🔨구현 내용
- [CollectionView 구현](#collectionview-구현)
    - [FlowLayout 적용](#flowlayout-생성)
    - [DiffableDataSource 적용](#diffabledatasource-적용)
- [ARC, CaptureList를 활용한 Memory Leak 방지](#capturelist-메모리-누수-방지)
- [이미지 캐싱처리](#이미지-캐싱처리)
- [Follower 정보에 대한 Paginating 구현](#paginating-and-loadingview-구현)
- [SearchBar 기능 구현](#searchbar-기능-구현)
<br><br>


### CollectionView 구현

#### FlowLayout 생성

<img width="225" alt="스크린샷 2022-01-03 오후 9 17 46" src="https://user-images.githubusercontent.com/56648865/147929495-b9666491-18a5-49a2-a967-f97bf7862834.png">

```swift
struct UIHelper {
    static func createdThreeColumnFlowLayout(in view: UIView) -> UICollectionViewFlowLayout {
        let width = view.bounds.width
        let padding: CGFloat = 12
        let minimumItemSpacing: CGFloat = 10
        let availableWidth = width - (padding * 2) - (minimumItemSpacing * 2)
        let itemWidth = availableWidth / 3
        
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.sectionInset = UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)
        flowLayout.itemSize = CGSize(width: itemWidth, height: itemWidth + 40)
        
        return flowLayout
    }
}
```
- grid형태의 Layout을 구현하기 위해 FlowLayout을 적용했습니다. 세로 scroll을 위해 default scrollDirection을 사용했고 각 item의 사이즈는 `view.bounds` 너비에 세 개씩 출력되도록 수치값을 계산하였으며 섹션 전체에 마진을 주었습니다.
<br>


#### DiffableDataSource 적용

![화면 기록 2022-01-05 오후 2 49 06](https://user-images.githubusercontent.com/56648865/148171323-99bca1be-32be-40aa-b1da-ed4044f0836a.gif)
![화면 기록 2022-01-05 오후 3 04 18](https://user-images.githubusercontent.com/56648865/148170677-e7a42214-4246-49d4-9d5e-f071f5e4f1e2.gif)


<왼쪽: 기존 DataSource, 오른쪽: DiffableDataSource>

- **DiffableDataSource를 사용한 이유:**<br>
    - animation효과를 사용하여 더 나은 UX, 즉 SearchBarResult에 따라 자연스럽게 갱신되는 CollectionView를 구현하기위하여 적용하였습니다.
    - 기존 DataSource는 변경될 데이터를 DataSource에게 따로 알려주고 reloadData()메서드를 통하여 DataSource의 변경사항을 직접 UI에 동기화해줘야하는 번거로움이 있었지만 `DiffableDataSource는 갱신될 상태를 Snapshot을 구성하고 apply() 해주기만하면 UI에 적용되기 때문에 유지보수 측면에서도 편하다고 판단하여 적용하였습니다.
<br><br>

- **Hashable**
```swift
func configureDataSource() {
    dataSource = UICollectionViewDiffableDataSource<Section, Follower>(collectionView: collectionView, cellProvider: { (collectionView, indexPath, follower) -> UICollectionViewCell? in
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FollowerCell.reuseID, for: indexPath) as! FollowerCell
        cell.set(follower: follower)
            
        return cell
        })
    }
```

기존에 DataSource메서드인 CellForRowAt에서 처리해주던 코드를 DiffableDataSource이 instantiate될 때 cellProvider를 통해 전달해줍니다. General type인 DiffableDataSource에게 Section Identifier와 Item Identifier를 알려주어야 합니다.  

    
```swift
struct Follower: Codable, Hashable {
    var login: String
    var avatarUrl: String
}
```
```swift
enum Section {
   case main
}
```
 Section 과 Item으로써 전달되는 타입은 모두 Hashable을 채택하고 있어야합니다. enum은 custom type을 사용하지 않는한 Hashable이 자동 적용되고 Follower type에서는 모든 프로퍼티가 Hashable하기 때문에 `hash(into:)`에 대한 처리없이 Hashable만 채택해주었습니다.
<br><br>

### CaptureList 메모리 누수 방지

```swift
class FollowerListViewController: UIViewController {
    
    // code
    
    var followers: [Follower] = []
    
    //code
    
    func getFollwers(username: String, page: Int) {
        showLoadingView()
        NetworkManager.shared.getFollowers(for: username, page: page) { [weak self] result in
            guard let self = self else { return }
            self.dismissLoadingView()
            switch result {
            case .success(let followers):
                if followers.count < 100 {
                    self.hasMoreFollowers = false
                }
                self.followers.append(contentsOf: followers)
                
                if self.followers.isEmpty {
                    let message = "This user doesn't have any followers. Go follow them ☺️."
                    DispatchQueue.main.async {
                        self.showEmptyStateView(with: message, in: self.view)
                    }
                }
                
                self.updateData(on: self.followers)
                
            case .failure(let error):
                self.presentGithubFollwerAlertOnMainThread(title: "Bad Stuff Happened", message: error.rawValue, buttonTitle: "Ok")
            }
        }
    }
```

위의 코드에서는 NetworkManager 인스턴스의 getFollowers()메서드가 실행되면서 전달되는 escaping closure 코드에서 **참조 타입인 FollowerListViewController**를 self로써 참조하고 있습니다. 때문에 NetworkManager는 FollowerListViewController를 강하게 참조하고 있고 NetworkManager 또한 FollowerListViewContorller의 getFollowers메서드에서 참조되어 지고 있습니다. 이는 강한 순환참조를 만들게됩니다. reference count가 올라가지 않게하여 capture list인 `[weak self]`를 통하여 이를 방지해주었습니다.
<br><br>

### 이미지 캐싱처리

- CollectionView scroll시 계속해서 네트워킹 작업을하여 이미지를 다운받아 업로드가 이루어지는 것은 비효율적이기 때문에 앱이 종료되기 이전까지는 이미 다운로드 받았던 이미지일 경우에는 메모리에서 가져와서 사용하도록 NSCache를 통해 메모리캐싱을 구현하였습니다.
- NetworkManger에 내부에 구현하여 싱글톤 인스턴스를 통해 단하나만 사용되도록 구현하였습니다.
<br><br>

### Paginating & LadingView 구현

![화면 기록 2022-01-07 오후 8 03 42](https://user-images.githubusercontent.com/56648865/148535251-c700d6d1-0c77-46a1-8528-77b690ea704f.gif)

```swift
"https://api.github.com/users/\(username)/followers?per_page=100&page=\(page)"
```

- API의 endpoint URL에 100개의 사진씩 불러오도록 명시하였습니다.

```swift
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let height = scrollView.frame.size.height
        
        if offsetY > contentHeight - height {
            guard hasMoreFollowers else { return }
            page += 1
            getFollwers(username: username, page: page)
        }
```

- 만약 CollectionView에서 드래그한 스크롤범위가 전체 contents영역의 높이에서 화면의 frame높이를 뺀것보다 더 길면, 즉 화면의 끝까지 드래그를 하면 다시한번 네트워크 요청을 통해 그 다음 100개의 data를 받아오도록 구현하였습니다.

```swift
    func showLoadingView() {
        containerView = UIView(frame: view.bounds)
        view.addSubview(containerView)
        
        containerView.backgroundColor = .systemBackground
        containerView.alpha = 0
        
        UIView.animate(withDuration: 0.25) {
            containerView.alpha = 0.8
        }
        
        let activityIndicator = UIActivityIndicatorView(style: .large)
        containerView.addSubview(activityIndicator)
        
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor )
        ])
        
        activityIndicator.startAnimating()
    }
    
    func dismissLoadingView() {
        DispatchQueue.main.async {
            containerView.removeFromSuperview()
            containerView = nil
        }
    }
```

- containerView를 활용하여 메서드 실행시 animate효과를 사용하여 containerView의 투명도를 조절하여 화면에 출력합니다. 
- activityIndicator를 이용하여 처리하고있는 작업이 진행중이면 containerView가 dismiss되지 않고 로딩 하는 animation이 출력되도록 합니다.

<img width="753" alt="스크린샷 2022-01-07 오후 8 25 55" src="https://user-images.githubusercontent.com/56648865/148537522-13241220-b795-442e-a43f-b0992afbde5c.png">


- showloadingView를 구현하여 NetworkManager의 getFollowers메서드가 실행되기 직전에 띄우고 getFollowers메서드가 실행이 끝나고 completionHandler가 실행될 때, 즉 데이터를 이미 받아온 후 사라지게 구현하였습니다.
<br><br>


### SearchBar 기능 구현

```swift
extension FollowerListViewController: UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        guard let filter = searchController.searchBar.text, !filter.isEmpty else { return }
        filteredFollowers = followers.filter { $0.login.lowercased().contains(filter.lowercased())
        }
        updateData(on: filteredFollowers)
    }
}

extension FollowerListViewController: UISearchBarDelegate {
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        updateData(on: followers)
    }
}

```
- UISearchResultsUpdating을 채택하여 SearchBar에 입력이 될경우 입력된 값으로 filter메서드를 적용하여 filterdFollowers배열에 결과를 저장하고 이를 snapshot에 적용하여 colletionView를 갱신시켜 줍니다.
- UISearchBarDelegate를 채택하여 SearchBar의 Cancel버튼을 클릭할시 기존의 전체 데이터가 담겨있는 followers배열을 통해 다시 새로운 snapshot을 적용하여 collectionView를 갱신시켜 줍니다.

## 📝학습 내용
- UICollectionView
- DiffableDataSource
- Closure Capture & Capture list
- Memory Cache
