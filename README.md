# githubFollowers - Feat.Networking

## 📕작업 배경
- 앱에서 사용할 데이터를 [Github API](https://docs.github.com/en/rest)로부터 JSON형태로 받아옵니다.
- URLSession을 활용하여 API와 http통신(GET)을 합니다.
- http통신을 진행할 때 API로 부터 전달받은 데이터, Response, 에러에 대한 처리를 해줍니다. 

## 🔨구현 내용
- [API에서 받아온 JSON데이터를 Decoding할 Model구현](#model-구현)
- [URLSession을 통하여 API와 통신할 네트워크 매니져 구현](#networkmanager-구현)
- [Result Type을 통한 네트워크 매니저 Refactoring](#result-type-refactoring)

### Model 구현

```swift
struct User: Codable {
    var login: String
    var avatarUrl: String
    var name: String?
    var location: String?
    var bio: String?
    var publicRepos: Int
    var publicGists: Int
    var htmlUrl: String
    var following: Int
    var followers: Int
    var createdAt: String
}

struct Follower: Codable {
    var login: String
    var avatarUrl: String
}
```
[API문서](https://docs.github.com/en/rest/reference/users#get-a-user)에서 필요한 User, Follower의 JSON Key를 확인하여 필요한 모델을 구현했습니다.

GitHub 계정에 따라 존재하지 않을 수도 있는 값에 대해선 model 프로퍼티 타입의 Optional타입으로 선언하였습니다.

decoding시에 `.convertFromSnakeCase`를 사용하기 위해 CodingKey를 사용하지 않았습니다.


### NetworkManager 구현

```swift
class NetworkManager {
    static let shared = NetworkManager()
    let baseURL = "https://api.github.com/users/"
    
    private init() {}
    
    func getFollowers(for username: String, page: Int, completion: @escaping (Result<[Follower], GithubFollowerError>) -> Void) {
        let endpoint = baseURL + "\(username)/followers?_per_page=100&page=\(page)"
        
        guard let url = URL(string: endpoint) else {
            completion(.failure(.invalidUsername))
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            
            if let _ = error {
                completion(.failure(.unableToComplete))
            }
            
            guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
                completion(.failure(.invalidResponse))
                return
            }
            
            guard let data = data else {
                completion(.failure(.invalidData))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let followers = try decoder.decode([Follower].self, from: data)
                completion(.success(followers))
            } catch {
                completion(.failure(.invalidData))
            }
        }
        
        task.resume()
    }
}
```
#### NetworkManager Singleton으로 구현한 이유
- NetworkManager객체의 특성상 싱글턴으로 구현된 URLSession.shared 객체, 즉 제한된 자원을 통해 작업을하는 객체이기 때문에 동작의 직관적인 이해를 위하여 싱글턴으로 구현하였습니다.

#### Singleton으로 구현하여 발생할 수 있는 문제점
- 싱글턴 객체인 URLSession의 shared 객체가 아닌 예를들어 테스트 객체 MockURLSession을 구현하여 테스트 용도로 사용하려할 때 싱글턴의 특성상 private init()으로 인하여 다른 형태의 URLSession 객체를 주입받을 수 없게됩니다.

#### URLSession shard객체 사용
- URLSession configuration을 통하여 앱의 상태에 따른 동작, 캐싱에 대해서 별다른 설정을 해주지않기 때문에 사용하였습니다.
- shared 객체를 사용할시에는 task실행데 대한 결과값의 검증 및 사용을 completion Handler에서 처리하게 됩니다.



### Result Type Refactoring

#### 수정 전

```swift
 func getFollowers(for username: String, page: Int, completion: @escaping ([Follower]?, ErrorMessage?) -> Void) {
        let endpoint = baseURL + "\(username)/followers?_per_page=100&page=\(page)"
        
        guard let url = URL(string: endpoint) else {
            completion(nil, .invalidUsername)
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            
            if let _ = error {
                completion(nil, .unableToComplete)
            }
            
            guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
                completion(nil, .invalidData)
                return
            }
            
            guard let data = data else {
                completion(nil, .invalidData)
                return
            }
            
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let followers = try decoder.decode([Follower].self, from: data)
                completion(followers, nil)
            } catch {
                completion(nil, .invalidData)
            }
        }
        
        task.resume()
    }
```

```swift
NetworkManager.shared.getFollowers(for: username, page: 1) { (followers, errorMessage) in
            guard let followers = followers else {
                self.presentGithubFollwerAlertOnMainThread(title: "Bad Stuff Happened", message: errorMessage!.rawValue, buttonTitle: "Ok")
                return
            }
            
            print("Followers.count = \(followers.count)")
            print(followers)
```

- dataTask()동작이 이루어지면서 받아온 error, response, data에 대하여 처리를 한 뒤 completion 코드를 실행하는 메서드입니다. getFollower() 메서드의 completion parameter타입을 ([Followers]?, ErrorMessage?)로 구현하였습니다. completion Handler 호출시 전달되는 argument들을 따로따로 직접 전달해야합니다. 또한 getFollower()메서드 호출시 전달된 argument에 대해서 옵셔널 바인딩을 통하여 처리를 해주었습니다.

### 수정 후

```swift
func getFollowers(for username: String, page: Int, completion: @escaping (Result<[Follower], GithubFollowerError>) -> Void) {
        let endpoint = baseURL + "\(username)/followers?_per_page=100&page=\(page)"
        
        guard let url = URL(string: endpoint) else {
            completion(.failure(.invalidUsername))
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            
            if let _ = error {
                completion(.failure(.unableToComplete))
            }
            
            guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
                completion(.failure(.invalidResponse))
                return
            }
            
            guard let data = data else {
                completion(.failure(.invalidData))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let followers = try decoder.decode([Follower].self, from: data)
                completion(.success(followers))
            } catch {
                completion(.failure(.invalidData))
            }
        }
        
        task.resume()
    }
```

```swift
        NetworkManager.shared.getFollowers(for: username, page: 1) { result in
            
            switch result {
            case .success(let followers):
                print("Followers.count = \(followers.count)")
                print(followers)
            case .failure(let error):
                self.presentGithubFollwerAlertOnMainThread(title: "Bad Stuff Happened", message: error.rawValue, buttonTitle: "Ok")
```

- getFollower()메서드의 parameter 타입을 Result타입으로 선언해줬습니다. completion()호출시에 .success, .failure를 통한 더 직관적으로 이해하기 쉬운 코드를 작성할 수 있습니다. Result 타입은 Generic Enum 타입으로 정의되어 있기때문에 getFollower()호출시 completion handler코드에 .success, .failure case를 통하여 직관적으로 처리해줄 수 있습니다.

## 📝학습 내용
- URLSession
- URL Loading System
- Fetching website Data into Memory
- Singleton
