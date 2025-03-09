
import SwiftUI


struct GroupsView: View {
    let accessToken: String
    @State private var groups: [Group] = []
    
    var body: some View {
        List(groups) { group in
            Text(group.name)
        }
        .navigationTitle("Группы")
        .onAppear { fetchGroups() }
    }
}

extension GroupsView {
    func fetchGroups() {
        let urlString = "https://api.vk.com/method/groups.get?extended=1&access_token=\(accessToken)&v=5.131"
        NetworkService.shared.fetchData(urlString) { (response: [Group]?) in
            groups = response ?? []
        }
    }
}
