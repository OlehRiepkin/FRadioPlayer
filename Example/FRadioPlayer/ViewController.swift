//
//  ViewController.swift
//  FRadioPlayerDemo
//
//  Created by Fethi El Hassasna on 2017-11-11.
//  Copyright © 2017 Fethi El Hassasna. All rights reserved.
//

import UIKit
import MediaPlayer
import FRadioPlayer


class ViewController: UIViewController {
    
    // IB UI
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var trackLabel: UILabel!
    @IBOutlet weak var infoContainer: UIView!
    @IBOutlet weak var artworkImageView: UIImageView!
    @IBOutlet weak var playButton: UIButton!
    
    // Singleton ref to player
    let player: FRadioPlayer = FRadioPlayer.shared
    
    // List of stations
    let stations = [Station(name: "AZ Rock Radio",
                                       detail: "We Know Music from A to Z",
                                       url: URL(string: "http://cassini.shoutca.st:9300/stream")!,
                                       image: #imageLiteral(resourceName: "station4")),
                               
                               Station(name: "Newport Folk Radio",
                                       detail: "Are you ready to Folk?",
                                       url: URL(string: "http:rfcmedia.streamguys1.com/Newport.mp3")!,
                                       image: #imageLiteral(resourceName: "station2")),
                               
                               Station(name: "Absolute Country Hits Radio",
                                       detail: "The Music Starts Here",
                                       url: URL(string: "http:strm112.1.fm/acountry_mobile_mp3")!,
                                       image: #imageLiteral(resourceName: "station1")),
                               
                               Station(name: "The Alt Vault",
                                       detail: "Your Lifestyle... Your Music!",
                                       url: URL(string: "http:jupiter.prostreaming.net/altmixxlow")!,
                                       image: #imageLiteral(resourceName: "station3"))]
    
    // Selected station index
    var selectedIndex = 0 {
        didSet {
            defer {
                selectStation(at: selectedIndex)
                updateNowPlayingUI()
            }
            
            guard 0..<stations.endIndex ~= selectedIndex else {
                selectedIndex = selectedIndex < 0 ? stations.count - 1 : 0
                return
            }
        }
    }
    
    var currentArtworkImage: UIImage? {
        didSet {
            updateNowPlayingUI()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "FRadioPlayer"
        
        // Set the delegate for the radio player
        player.httpHeaderFields = ["user-agent": "FRadioPlayer"]
        player.addObserver(self)
        
        // Show current player state
        statusLabel.text = player.state.description
        
        tableView.tableFooterView = UIView()
        infoContainer.isHidden = true
        
        setupRemoteTransportControls()
    }
    
    @IBAction func playTap(_ sender: Any) {
        player.togglePlaying()
    }
    
    @IBAction func stopTap(_ sender: Any) {
        player.stop()
    }
    
    @IBAction func previousTap(_ sender: Any) {
        previous()
    }
    
    @IBAction func nextTap(_ sender: Any) {
        next()
    }
    
    func next() {
        selectedIndex += 1
    }
    
    func previous() {
        selectedIndex -= 1
    }
    
    func selectStation(at position: Int) {
        player.radioURL = stations[selectedIndex].url
        tableView.selectRow(at: IndexPath(item: position, section: 0), animated: true, scrollPosition: .none)
    }
}

// MARK: - FRadioPlayerObserver

extension ViewController: FRadioPlayerObserver {
    
    func radioPlayer(_ player: FRadioPlayer, playerStateDidChange state: FRadioPlayer.State) {
        statusLabel.text = state.description
    }
    
    func radioPlayer(_ player: FRadioPlayer, playbackStateDidChange state: FRadioPlayer.PlaybackState) {
        playButton.isSelected = player.isPlaying
    }
    
    func radioPlayer(_ player: FRadioPlayer, itemDidChange url: URL?) {
        updateNowPlayingUI()
    }
    
    func radioPlayer(_ player: FRadioPlayer, metadataDidChange metadata: FRadioPlayer.Metadata?) {
        updateNowPlayingUI()
    }
    
    func radioPlayer(_ player: FRadioPlayer, artworkDidChange artworkURL: URL?) {
        // Please note that the following example is for demonstration purposes only, consider using asynchronous network calls to set the image from a URL.
        guard let artworkURL = artworkURL, let data = try? Data(contentsOf: artworkURL) else {
            currentArtworkImage = stations[selectedIndex].image
            return
        }

        currentArtworkImage = UIImage(data: data) ?? stations[selectedIndex].image
    }
}

// MARK: - UITableViewDelegate

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return stations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = stations[indexPath.item].name
        cell.detailTextLabel?.text = stations[indexPath.item].detail
        cell.imageView?.image = stations[indexPath.item].image
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedIndex = indexPath.item
    }
}

// MARK: - Remote Controls / Lock screen

extension ViewController {
    
    func setupRemoteTransportControls() {
        // Get the shared MPRemoteCommandCenter
        let commandCenter = MPRemoteCommandCenter.shared()
        
        // Add handler for Play Command
        commandCenter.playCommand.addTarget { [unowned self] event in
            if self.player.rate == 0.0 {
                self.player.play()
                return .success
            }
            return .commandFailed
        }
        
        // Add handler for Pause Command
        commandCenter.pauseCommand.addTarget { [unowned self] event in
            if self.player.rate == 1.0 {
                self.player.pause()
                return .success
            }
            return .commandFailed
        }
        
        // Add handler for Next Command
        commandCenter.nextTrackCommand.addTarget { [unowned self] event in
            self.next()
            return .success
        }
        
        // Add handler for Previous Command
        commandCenter.previousTrackCommand.addTarget { [unowned self] event in
            self.previous()
            return .success
        }
    }
    
    func updateNowPlayingUI() {
        
        let metadata = player.currentMetadata
        
        // UI
        infoContainer.isHidden = (metadata == nil)
        artistLabel.text = metadata?.artistName
        trackLabel.text = metadata?.trackName
        artworkImageView.image = currentArtworkImage
    
        // Now Playing Info
        var nowPlayingInfo = [String : Any]()
        
        if let artist = metadata?.artistName {
            nowPlayingInfo[MPMediaItemPropertyArtist] = artist
        }
        
        nowPlayingInfo[MPMediaItemPropertyTitle] = metadata?.trackName ?? stations[selectedIndex].name
        
        if let image = currentArtworkImage {
            nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size, requestHandler: { _ -> UIImage in
                return image
            })
        }
        
        // Set the metadata
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
}

// MARK: - UINavigationController

extension UINavigationController {
    open override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}
