//
//  ArtistCell.swift
//  Discography
//
//  Created by Antonio Strijdom on 20/02/2018.
//  Copyright © 2018 Antonio Strijdom. All rights reserved.
//

import UIKit

/// Table view cell for displaying artist information
class ArtistCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
