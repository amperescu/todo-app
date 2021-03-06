//
//  ViewController.swift
//  TodoApp
//
//  Created by Antonela Madalina on 10/09/2020.
//  Copyright © 2020 AM Perescu. All rights reserved.
//

import UIKit
import RealmSwift
import ChameleonFramework

class TodoListViewController: SwipeTableViewController {
    
    let realm = try! Realm()

    @IBOutlet weak var searchBar: UISearchBar!
    var todoArray: Results<Todo>?
    var selectedCategory: Category? {
        didSet{
            loadTodos()
        }
    }
        
    // MARK: - View controller lifecycle methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask))
        
        tableView.separatorStyle = .none
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if let colourHex = selectedCategory?.colour {
            title = selectedCategory!.name
            
            guard let navBar = navigationController?.navigationBar else { fatalError("Navigation controller does not exist.")
            }
            let navBarAppearance = UINavigationBarAppearance()
            
            if let navBarColour = UIColor(hexString: colourHex) {
                navBarAppearance.largeTitleTextAttributes = [.foregroundColor: ContrastColorOf(navBarColour, returnFlat: true)]
                navBarAppearance.backgroundColor = navBarColour
                
                navBar.tintColor = ContrastColorOf(navBarColour, returnFlat: true)
                navBar.standardAppearance = navBarAppearance
                navBar.scrollEdgeAppearance = navBarAppearance
                
                searchBar.barTintColor = navBarColour
                searchBar.searchTextField.backgroundColor = UIColor.white
            }
        }
    }
    
    //MARK: - TableView Datasource Methods
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return todoArray?.count ?? 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        
        if let todo = todoArray?[indexPath.row] {
            cell.textLabel?.text = todo.title
            if let colour = UIColor(hexString: selectedCategory!.colour)?.darken(byPercentage: CGFloat(indexPath.row) / CGFloat(todoArray!.count)) {
                cell.backgroundColor = colour
                cell.textLabel?.textColor = ContrastColorOf(colour, returnFlat: true)
            }
            if todo.done == true {
                cell.accessoryType = .checkmark
            } else {
                cell.accessoryType = .none
            }
        } else {
            cell.textLabel?.text = "No Todos Added"
        }
        
        return cell
    }
    
    //MARK: - Swipe delete cell
    
    override func updateModel(at indexPath: IndexPath) {
        if let todo = todoArray?[indexPath.row] {
            do {
                try realm.write {
                    realm.delete(todo)
                }
            } catch {
                print("Error deleting the todo \(error)")
            }
        }
    }
    
    //MARK: - TableView Delegate Methods
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let item = todoArray?[indexPath.row] {
            do {
                try realm.write{
                    // realm.delete(item)
                    item.done = !item.done
                }
            } catch {
                print("Error saving done status, \(error)")
            }
        }
        
        tableView.reloadData()
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    //MARK: - Add New Todos
    
    @IBAction func addButtonPressed(_ sender: UIBarButtonItem) {
        var textField = UITextField()
        let alert = UIAlertController(title: "Add New Todoee Item", message: "", preferredStyle: .alert)

        let action  = UIAlertAction(title: "Add Item", style: .default) { (action) in
            if let currentCategory = self.selectedCategory {
                do {
                    try self.realm.write {
                        let newTodo = Todo()
                        newTodo.title = textField.text!
                        newTodo.dateCreated = Date()
                        currentCategory.items.append(newTodo)
                    }
                } catch {
                    print("Error writing new todos \(error)")
                }
            }
            
            self.tableView.reloadData()
        }

        alert.addTextField { (alertTextField) in
            alertTextField.placeholder = "Create new item"
            textField = alertTextField
        }

        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }

    
    func loadTodos() {
        
        todoArray = selectedCategory?.items.sorted(byKeyPath: "title", ascending: true)
        
        tableView.reloadData()
    }
}
//MARK: - UISearchBarDelegate

extension TodoListViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        todoArray = todoArray?.filter("title CONTAINS[cd] %@", searchBar.text!).sorted(byKeyPath: "dateCreated", ascending: true)
        
        tableView.reloadData()
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchBar.text?.count == 0 {
            loadTodos()
            DispatchQueue.main.async {
                searchBar.resignFirstResponder()
            }
        }
    }
}

