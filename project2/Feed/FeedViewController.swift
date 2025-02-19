//
//  FeedViewController.swift
//  lab-insta-parse
//
//  Created by Charlie Hieger on 11/1/22.
//

import UIKit

// TODO: Import Parse Swift
import ParseSwift

class FeedViewController: UIViewController {
    
    @IBOutlet weak var Lpic: UIImageView!
    @IBOutlet weak var PostCreate: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    private let refreshControl = UIRefreshControl()
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private var isLoadingMorePosts = false

    private var posts = [Post]() {
        didSet {
            // Reload table view data any time the posts variable gets updated.
            tableView.reloadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()


        tableView.delegate = self
        tableView.dataSource = self
        tableView.allowsSelection = false
        
        self.navigationController?.navigationBar.titleTextAttributes = [
                .foregroundColor: UIColor.white,
                .font: UIFont(name: "AmericanTypewriter", size: 18) ?? UIFont.systemFont(ofSize: 18)
            ]
        
        setupRefreshControl()
        setupActivityIndicator()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        queryPosts()
    }
    private func setupRefreshControl() {
            refreshControl.tintColor = UIColor.systemBlue

            refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)

            if #available(iOS 10.0, *) {
                tableView.refreshControl = refreshControl
            } else {
                tableView.addSubview(refreshControl)
            }
        }
    private func setupActivityIndicator() {
            activityIndicator.center = view.center
            view.addSubview(activityIndicator)
        }

    @objc private func refreshData() {
            queryPosts()
        }


    private func queryPosts() {

        if !refreshControl.isRefreshing {
                    activityIndicator.startAnimating()
                }
        
        let query = Post.query()
            .include("user")
            .order([.descending("createdAt")])

        query.find { [weak self] result in
            self?.activityIndicator.stopAnimating()
            self?.refreshControl.endRefreshing()
            switch result {
            case .success(let posts):
                self?.posts = posts
            case .failure(let error):
                self?.showAlert(description: error.localizedDescription)
            }
        }
    }
    private func loadMorePosts() {
        activityIndicator.startAnimating()

            
        let query = Post.query()
            .include("user")
            .order([.descending("createdAt")])
            .limit(10)
            

        query.find { [weak self] result in
            self?.activityIndicator.stopAnimating()
            switch result {
            case .success(let newPosts):
                self?.posts.append(contentsOf: newPosts)
            case .failure(let error):
                self?.showAlert(description: error.localizedDescription)
                }
            self?.isLoadingMorePosts = false
            }
        }
    
    @IBAction func onLogOutTapped(_ sender: Any) {
        showConfirmLogoutAlert()
    }

    private func showConfirmLogoutAlert() {
        let alertController = UIAlertController(title: "Log out of your account?", message: nil, preferredStyle: .alert)
        let logOutAction = UIAlertAction(title: "Log out", style: .destructive) { _ in
            NotificationCenter.default.post(name: Notification.Name("logout"), object: nil)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alertController.addAction(logOutAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true)
    }

    private func showAlert(description: String? = nil) {
        let alertController = UIAlertController(title: "Oops...", message: "\(description ?? "Please try again...")", preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default)
        alertController.addAction(action)
        present(alertController, animated: true)
    }
}

extension FeedViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell", for: indexPath) as? PostCell else {
            return UITableViewCell()
        }
        cell.configure(with: posts[indexPath.row])
        return cell
    }
}

extension FeedViewController: UITableViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y > scrollView.contentSize.height - scrollView.frame.size.height - 50 {
            if !isLoadingMorePosts {
                isLoadingMorePosts = true
                loadMorePosts()
            }
        }
    }
}
