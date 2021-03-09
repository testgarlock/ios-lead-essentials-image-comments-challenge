//
//  ImageCommentPresenterTests.swift
//  EssentialFeedTests
//
//  Created by Eric Garlock on 3/8/21.
//  Copyright © 2021 Essential Developer. All rights reserved.
//

import XCTest
import EssentialFeed

struct ImageCommentViewModel {
	public let comments: [ImageComment]
}

struct ImageCommentLoadingViewModel {
	public let isLoading: Bool
	
	static var loading: ImageCommentLoadingViewModel {
		return ImageCommentLoadingViewModel(isLoading: true)
	}
	static var finished: ImageCommentLoadingViewModel {
		return ImageCommentLoadingViewModel(isLoading: false)
	}
}

struct ImageCommentErrorViewModel {
	public let message: String?
	
	static var clear: ImageCommentErrorViewModel {
		return ImageCommentErrorViewModel(message: nil)
	}
}

protocol ImageCommentView {
	func display(_ viewModel: ImageCommentViewModel)
}

protocol ImageCommentLoadingView {
	func display(_ viewModel: ImageCommentLoadingViewModel)
}

protocol ImageCommentErrorView {
	func display(_ viewModel: ImageCommentErrorViewModel)
}

class ImageCommentPresenter {
	
	public static var title: String {
		return NSLocalizedString("COMMENT_VIEW_TITLE", tableName: "ImageComments", bundle: Bundle(for: ImageCommentPresenter.self), comment: "Title for the comments view")
	}
	
	public static var errorMessage: String {
		return NSLocalizedString("COMMENT_VIEW_ERROR_MESSAGE", tableName: "ImageComments", bundle: Bundle(for: ImageCommentPresenter.self), comment: "Error message for the comments view")
	}
	
	private let commentView: ImageCommentView
	private let loadingView: ImageCommentLoadingView
	private let errorView: ImageCommentErrorView
	
	public init(commentView: ImageCommentView, loadingView: ImageCommentLoadingView, errorView: ImageCommentErrorView) {
		self.commentView = commentView
		self.loadingView = loadingView
		self.errorView = errorView
	}
	
	public func didStartLoadingComments() {
		loadingView.display(.loading)
		errorView.display(.clear)
	}
	
	public func didFinishLoadingComments(with comments: [ImageComment]) {
		loadingView.display(.finished)
		commentView.display(ImageCommentViewModel(comments: comments))
	}
	
	public func didFinishLoadingComments(with error: Error) {
		loadingView.display(.finished)
		errorView.display(ImageCommentErrorViewModel(message: ImageCommentPresenter.errorMessage))
	}
	
}

class ImageCommentPresenterTests: XCTestCase {

	func test_title_isLocalized() {
		XCTAssertEqual(ImageCommentPresenter.title, localized("COMMENT_VIEW_TITLE"))
	}
	
	func test_init_doesNotSendMessageToView() {
		let (_, view) = makeSUT()
		
		XCTAssert(view.messages.isEmpty, "Expected no view messages")
	}
	
	func test_didStartLoadingComments_displaysNoErrorMessageAndStartsLoading() {
		let (sut, view) = makeSUT()
		
		sut.didStartLoadingComments()
		
		XCTAssertEqual(view.messages, [
			.display(message: nil),
			.display(isLoading: true)
		])
	}
	
	func test_didFinishLoadingComments_displaysCommentsAndStopsLoading() {
		let (sut, view) = makeSUT()
		let comment0 = makeComment(id: UUID(), message: "message0", createdAt: Date(), username: "username0")
		let comment1 = makeComment(id: UUID(), message: "message1", createdAt: Date(), username: "username1")
		
		sut.didFinishLoadingComments(with: [comment0, comment1])
		
		XCTAssertEqual(view.messages, [
			.display(isLoading: false),
			.display(comments: [comment0, comment1])
		])
	}
	
	func test_didFinishLoadingCommentsWithError_displaysLocalizedErrorAndStopsLoading() {
		let (sut, view) = makeSUT()
		let error = NSError(domain: "error", code: 0)
		
		sut.didFinishLoadingComments(with: error)
		
		XCTAssertEqual(view.messages, [
			.display(isLoading: false),
			.display(message: localized("COMMENT_VIEW_ERROR_MESSAGE"))
		])
	}
	
	// MARK: - Helpers
	private func makeSUT() -> (sut: ImageCommentPresenter, view: ViewSpy) {
		let view = ViewSpy()
		let sut = ImageCommentPresenter(commentView: view, loadingView: view, errorView: view)
		trackForMemoryLeaks(view)
		trackForMemoryLeaks(sut)
		return (sut, view)
	}
	
	private func makeComment(id: UUID, message: String, createdAt: Date, username: String) -> ImageComment {
		return ImageComment(
			id: id,
			message: message,
			createdAt: createdAt,
			author: ImageCommentAuthor(username: username))
	}
	
	private func localized(_ key: String, file: StaticString = #filePath, line: UInt = #line) -> String {
		let table = "ImageComments"
		let bundle = Bundle(for: ImageCommentPresenter.self)
		let value = bundle.localizedString(forKey: key, value: nil, table: table)
		if value == key {
			XCTFail("Missing localized string for key: \(key) in table: \(table)", file: file, line: line)
		}
		return value
	}
	
	private class ViewSpy: ImageCommentView, ImageCommentLoadingView, ImageCommentErrorView {
		
		enum Message: Hashable {
			case display(comments: [ImageComment])
			case display(isLoading: Bool)
			case display(message: String?)
		}
		
		private(set) var messages = Set<Message>()
		
		func display(_ viewModel: ImageCommentViewModel) {
			messages.insert(.display(comments: viewModel.comments))
		}
		
		func display(_ viewModel: ImageCommentLoadingViewModel) {
			messages.insert(.display(isLoading: viewModel.isLoading))
		}
		
		func display(_ viewModel: ImageCommentErrorViewModel) {
			messages.insert(.display(message: viewModel.message))
		}
		
	}

}
