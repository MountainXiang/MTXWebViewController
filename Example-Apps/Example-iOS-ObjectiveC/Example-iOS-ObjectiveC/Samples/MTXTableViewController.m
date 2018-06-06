//
//  MTXTableViewController.m
//  Example-iOS-ObjectiveC
//
//  Created by MountainX on 2018/6/6.
//  Copyright © 2018年 MTX Software Technology Co.,Ltd. All rights reserved.
//

#import "MTXTableViewController.h"
#import "MTXWebViewController.h"

@interface MTXTableViewController () <UITextFieldDelegate>

@end

@implementation MTXTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

//- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
//#warning Incomplete implementation, return the number of sections
//    return 0;
//}
//
//- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
//#warning Incomplete implementation, return the number of rows
//    return 0;
//}

/*
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:<#@"reuseIdentifier"#> forIndexPath:indexPath];
    
    // Configure the cell...
    
    return cell;
}
*/

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    switch (indexPath.row) {
        case 0:
        {
            MTXWebViewController *webVC = [[MTXWebViewController alloc] initWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Swift" ofType:@"pdf"]]];
            [self.navigationController pushViewController:webVC animated:YES];
        }
            break;
        case 1:
        {
            MTXWebViewController *webVC = [[MTXWebViewController alloc] initWithURL:[NSURL URLWithString:@"http://www.baidu.com"]];
            [self.navigationController pushViewController:webVC animated:YES];
        }
            break;
        case 2:
        {
            MTXWebViewController *webVC = [[MTXWebViewController alloc] initWithURL:[NSURL URLWithString:@"http://www.youku.com"]];
            [self.navigationController pushViewController:webVC animated:YES];
        }
            break;
        case 3:
        {
            MTXWebViewController *webVC = [[MTXWebViewController alloc] initWithURL:[NSURL URLWithString:@"https://github.com/MountainXiang/MTXWebViewController"]];
            [self.navigationController pushViewController:webVC animated:YES];
            
        }
            break;
        case 4:
        {
            MTXWebViewController *webVC = [[MTXWebViewController alloc] initWithURL:[NSURL URLWithString:@"https://github.com/MountainXiang/MTXWebViewController/releases"]];
            [self.navigationController pushViewController:webVC animated:YES];
        }
            break;
        default:
            break;
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - IBAction
- (IBAction)clearCacheBtnClicked:(id)sender {
    NSLog(@"clearCacheBtnClicked");
}

#pragma mark - UITextFieldDelegate
-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self.view endEditing:YES];
    
    NSString *urlStr = [textField.text copy];
    NSURL *url = [NSURL URLWithString:urlStr];
    if (url) {
        
        
        
    }
    return YES;
}

@end
