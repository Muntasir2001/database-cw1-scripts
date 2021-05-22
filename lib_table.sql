USE Library
GO

DROP TABLE CATALOGUE
CREATE TABLE CATALOGUE (
	ISBN						BigInt				NOT NULL, --random number needed
	Title						VarChar(105)		NOT NULL,
	Author						Char(15)			NOT NULL,
	SubjectArea					VarChar(50)			NOT NULL,
	BookDescription				VarChar(200)		NOT NULL,
	TotalNumberOfCopies			Int					NOT NULL,
	isLendable					BIT					NOT NULL,
	AvailableNumberOfCopies		Int					NOT NULL,
	CONSTRAINT				CataloguePK				PRIMARY KEY(ISBN)
)

DROP TABLE LIBRARY_MEMBER
CREATE TABLE LIBRARY_MEMBER (
	LibraryID					Int					NOT NULL,
	LastName					Char(10)			NOT NULL,
	FirstName					Char(10)			NOT NULL,
	PhoneNumber					Int					NOT NULL,
	isSenior					BIT					NOT NULL,
	StartOfMembership			Date				NOT NULL,
	EndOfMembership				Date				NOT NULL,
	EOMNotifyDate				Date				NOT NULL,
	NumOfBooksInHand			Int					NULL,
	NumOfBooksBorrowedInTotal	Int					NOT NULL,
	CONSTRAINT				LibraryMemberPK			PRIMARY KEY(LibraryID)
)

DROP TABLE LENDING_ACTIVITY
CREATE TABLE LENDING_ACTIVITY (
	LendingID					Int					NOT NULL, --random number needed
	LibraryID					Int					NOT NULL,
	ISBN						BigInt				NOT NULL,
	StartDateTime				DateTime			NOT NULL,
	EndDateTime					DateTime			NOT NULL,
	EndOfGracePeriod			DateTime			NOT NULL,
	ActualReturnDateTime		DateTime			NULL,
	CONSTRAINT				LendingActivityPK		PRIMARY KEY(LendingID),
	CONSTRAINT				LibraryIDFK				FOREIGN KEY(LibraryID)
								REFERENCES LIBRARY_MEMBER(LibraryID),
	CONSTRAINT				ISBNFK					FOREIGN KEY(ISBN)
								REFERENCES CATALOGUE(ISBN)
)

DROP TABLE STUDENT
CREATE TABLE STUDENT (
	LibraryID					Int					NOT NULL,
	StudentID					Int					NOT NULL,
	CampusAddress				VarChar(100)			NOT NULL,
	HomeAddress					VarChar(100)			NOT NULL,
	CONSTRAINT				StudentPK				PRIMARY KEY(LibraryID),
	CONSTRAINT				StudentAK				UNIQUE(StudentID),
	CONSTRAINT				StudentLibraryIDFK				FOREIGN KEY(LibraryID)
								REFERENCES LIBRARY_MEMBER(LibraryID)
)

DROP TABLE SENIOR
CREATE TABLE SENIOR (
	LibraryID					Int					NOT NULL,
	EmployeeID					Int					NOT NULL,
	CampusAddress				VarChar(100)			NOT NULL,
	HomeAddress					VarChar(100)			NOT NULL,
	CONSTRAINT				SeniorPK				PRIMARY KEY(LibraryID),
	CONSTRAINT				EmployeeAK				UNIQUE(EmployeeID),
	CONSTRAINT				SeniorLibraryIDFK				FOREIGN KEY(LibraryID)
								REFERENCES LIBRARY_MEMBER(LibraryID)
)

DROP TABLE BOOKS_NEEDED
CREATE TABLE BOOKS_NEEDED(
	ISBN					BigInt						NOT NULL, --random number needed
	Title					VarChar(105)			NOT NULL,
	Author					Char(15)				NOT NULL,
	SubjectArea				VarChar(50)				NOT NULL,
	BookDescription			VarChar(200)			NOT NULL,
	QuantityRequired		Int						NOT NULL,
	CONSTRAINT			BooksNeededPK				PRIMARY KEY(ISBN)
)

DROP TABLE LENDERS
CREATE TABLE LENDERS (
	LenderID				Int						NOT NULL,
	LenderName				Char(20)				NOT NULL,
	LenderAddress			VarChar(50)				NOT NULL,
	PhoneNumber				Int						NOT NULL,
	CONSTRAINT			LendersPK					PRIMARY KEY(LenderID)	
)

DROP TABLE BORROWING_ACTIVITY
CREATE TABLE BORROWING_ACTIVITY (
	BorrowingID				Int						NOT NULL,
	LenderID				Int						NOT NULL,
	ISBN					BigInt						NOT NULL,
	StartDateTime			DateTime				NOT NULL,
	DueDateTime				DateTime				NOT NULL,
	ActualReturnDateTime	DateTime				NULL,
	QuantityBorrowed		DateTime				NOT NULL,
	CONSTRAINT			BorrowingActivityPK			PRIMARY KEY(BorrowingID),
	CONSTRAINT			LenderIDFK					FOREIGN KEY(LenderID)
							REFERENCES LENDERS(LenderID),
	CONSTRAINT			B_AISBNFK						FOREIGN KEY(ISBN)
							REFERENCES BOOKS_NEEDED(ISBN)
)