USE Library
GO

--Write a query to find all books that are overdue (by at least 3 days) for return to the library.
SELECT *
FROM LENDING_ACTIVITY
WHERE GETDATE() > DATEADD(day, 3, EndOfGracePeriod) AND ActualReturnDateTime IS NULL;

-- Write a query to produce a list of customers who have made less than 5 loans in the past 3 months. Show appropriate customer and loan details in your answer.
SELECT LendingID, lm.LibraryID, ISBN, FirstName, LastName, StartDateTime as StartOfLoan, EndDateTime as EndOfLoan
FROM LENDING_ACTIVITY as la, LIBRARY_MEMBER as lm
WHERE lm.LibraryID = la.LibraryID AND NumOfBooksBorrowedInTotal < 5 AND StartDateTime BETWEEN (select dateadd(month, -3, getdate())) and GETDATE();

-- Write a query to produce the weekly lending report (loan-item-id description, start-date-time, due-date-time, actual-return-date-time, lender details
SELECT DATEADD(week, DATEDIFF(week, 0, StartDateTime), 0) 'Starting Week: ', LendingID, la.LibraryID, FirstName, LastName, StartDateTime, EndDateTime, ActualReturnDateTime as DateReturned
FROM LENDING_ACTIVITY as la
JOIN CATALOGUE
ON la.ISBN = CATALOGUE.ISBN
JOIN LIBRARY_MEMBER as lm
ON lm.LibraryID = la.LibraryID
GROUP BY  DATEADD(week, DATEDIFF(week, 0, StartDateTime), 0), LendingID, la.LibraryID, FirstName, LastName, StartDateTime, EndDateTime, ActualReturnDateTime
ORDER BY DATEADD(week, DATEDIFF(week, 0, StartDateTime), 0);

-- Write a stored procedure to provide a report showing current inter-library loans, showing all current inter-library loan items, including the partner library who loaned the item to Starlabs, the item details and the current loan duration calculated in days.
GO
DROP PROCEDURE interLibraryLoanReport

GO
CREATE PROC interLibraryLoanReport AS
DECLARE @borrowingID int,
@lenderID int,
@lenderName Char(20),
@ISBN BigInt,
@bookTitle VarChar(105),
@startDateTime DateTime,
@endDateTime DateTime,
@loanDuration int

--cursor declaration for getting the value
DECLARE INTER_LOAN CURSOR FOR
	SELECT BorrowingID ,ba.LenderID, LenderName, ba.ISBN, Title, StartDateTime, DueDateTime
	FROM BOOKS_NEEDED as bn, Lenders as l, BORROWING_ACTIVITY as ba
	WHERE ba.LenderID = l.LenderID AND bn.ISBN = ba.ISBN

BEGIN
	PRINT 'Inter-library Loan Report'

	OPEN INTER_LOAN
	FETCH NEXT FROM INTER_LOAN INTO @borrowingID, @lenderID, @lenderName, @ISBN, @bookTitle, @startDateTime, @endDateTime

	SET @loanDuration = DATEDIFF(day, GETDATE(), @endDateTime)
	
	WHILE @@FETCH_STATUS = 0
	BEGIN
		PRINT 'BorrowingID: ' + cast(@borrowingID as VarChar(15)) + '  ' + 'LenderID: ' + cast(@lenderID as VarChar(15)) + ' ' +  @lenderName + '  ' + 'Book Borrowed: ' + cast(@ISBN as VarChar(20)) + ' ' + @bookTitle + '    ' + 'Current Loan Duration: ' + cast(@loanDuration as VarChar(20)) + ' days' 

		FETCH NEXT FROM INTER_LOAN INTO @borrowingID, @lenderID, @lenderName, @ISBN, @bookTitle, @startDateTime, @endDateTime
		SET @loanDuration = DATEDIFF(day, GETDATE(), @endDateTime)
	END

	CLOSE INTER_LOAN
	DEALLOCATE INTER_LOAN
END

EXEC interLibraryLoanReport

-- Write a stored procedure to provide a report showing a monthly itemized statement of loans for each lender. The procedure should be able to accept appropriate parameter values to enable dynamic search by week, month or quarter (3 months) Include appropriate payment, tax (at 20% vat), and totals in your report
DROP PROC monthlyItemizedStatement

GO

ALTER PROC monthlyItemizedStatement @ID int, @startDate DateTime, @endDate DateTime 
AS
DECLARE @libraryID BigInt,
@firstName char(10),
@lastName char(10),
@startDateTime DateTime,
@endDateTime DateTime,
@endGracePeriod DateTime,
@actualReturnDateTime DateTime,
@ISBN BigInt,
@bookTitle VarChar(50),
@price int,
@priceVAT float

--cursor declaration
DECLARE LENDING CURSOR FOR
	SELECT la.LibraryID, FirstName, LastName, la.ISBN, Title, StartDateTime, EndDateTime, EndOfGracePeriod, ActualReturnDateTime
	FROM CATALOGUE as c, LIBRARY_MEMBER as lm, LENDING_ACTIVITY as la
	WHERE la.LibraryID = @ID AND lm.LibraryID = la.LibraryID AND la.ISBN = c.ISBN AND StartDateTime BETWEEN @startDate AND @endDate

BEGIN
	OPEN LENDING
	FETCH NEXT FROM LENDING INTO @libraryID, @firstName, @lastName, @ISBN, @bookTitle, @startDateTime, @endDateTime, @endGracePeriod, @actualReturnDateTime 

	PRINT '****** Monthly Itemized Statement for ' + @firstName + '******'
	PRINT ' '

	WHILE @@FETCH_STATUS = 0
		BEGIN
			PRINT '---------------'
			PRINT ' '
			PRINT cast(@libraryID as VarChar(20)) + '   ' + @firstName + ' ' + @lastName
			PRINT cast(@ISBN as VarChar(20)) + '   ' + @bookTitle
			PRINT 'Date borrowed: '  + cast(@startDateTime as VarChar(30)) + '  ' + 'Date due: '  + cast(@endDateTime as VarChar(30)) + '  ' + 'End Of Grace Period: '  + cast(@endGracePeriod as VarChar(30))

			IF @actualReturnDateTime IS NULL
				BEGIN
					PRINT 'Date Returned: Not returned yet'
				END
			ELSE
				BEGIN
					PRINT 'Date Returned: ' + cast(@actualReturnDateTime as VarChar(30))
				END

			IF @actualReturnDateTime IS NULL AND GETDATE() < @endGracePeriod
				BEGIN
					SET @price = 0
					PRINT 'Charge for this loan: £0'
				END
			ELSE IF @actualReturnDateTime IS NOT NULL AND GETDATE() < @endGracePeriod
				BEGIN
					PRINT 'Charge for this loan: £0'
				END
			ELSE IF @actualReturnDateTime IS NOT NULL AND GETDATE() > @endGracePeriod
				BEGIN
					PRINT 'Charge for this loan: £0'
				END
			ELSE IF GETDATE() > @endGracePeriod AND @actualReturnDateTime IS NULL
				BEGIN
					SET @price += 6
					PRINT 'Charge for this loan: £6'
				END

			PRINT ' '
			PRINT '---------------'

			FETCH NEXT FROM LENDING INTO @libraryID, @firstName, @lastName, @ISBN, @bookTitle, @startDateTime, @endDateTime, @endGracePeriod, @actualReturnDateTime
		END

		SET @priceVAT = (0.2 * @price) + @price
		PRINT 'Total Charge with VAT: £' + cast(@priceVAT as VarChar(10))

	CLOSE LENDING
	DEALLOCATE LENDING
END

exec monthlyItemizedStatement @ID = 1017, @startDate = '2020-04-01', @endDate = '2021-08-28'