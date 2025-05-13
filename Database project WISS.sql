
--WORKFORCE INFORMATION AND SECURITY SYSTEM (WISS)

CREATE DATABASE WIS;
USE WIS;


-- ========================================
-- TABLES SECTION
-- ========================================

--  Department table
CREATE TABLE Department (
    DepartmentID INT IDENTITY(1,1) PRIMARY KEY,
    DepartmentName NVARCHAR(100) NOT NULL UNIQUE,
    Description NVARCHAR(500) NULL,
    CreatedDate DATETIME DEFAULT GETDATE(),
    ModifiedDate DATETIME DEFAULT GETDATE()
);
GO

-- Position table
CREATE TABLE Position (
    PositionID INT IDENTITY(1,1) PRIMARY KEY,
    PositionName NVARCHAR(100) NOT NULL UNIQUE,
    Description NVARCHAR(500) NULL,
    PayGrade VARCHAR(20) NULL,
    CreatedDate DATETIME DEFAULT GETDATE(),
    ModifiedDate DATETIME DEFAULT GETDATE()
);
GO

-- Employee table
CREATE TABLE Employee (
    EmployeeID INT IDENTITY(1000,1) PRIMARY KEY,
    EmployeeCode VARCHAR(20) NOT NULL UNIQUE,
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Email NVARCHAR(100) NOT NULL UNIQUE,
    Phone VARCHAR(20) NULL,
    DepartmentID INT NOT NULL FOREIGN KEY REFERENCES Department(DepartmentID),
    PositionID INT NOT NULL FOREIGN KEY REFERENCES Position(PositionID),
    JoiningDate DATE NOT NULL,
    Salary DECIMAL(18,2) NOT NULL CHECK (Salary >= 0),
    Status VARCHAR(20) NOT NULL DEFAULT 'Active' CHECK (Status IN ('Active', 'Inactive', 'On Leave', 'Terminated')),
    ReportsTo INT NULL FOREIGN KEY REFERENCES Employee(EmployeeID),
    CreatedDate DATETIME DEFAULT GETDATE(),
    ModifiedDate DATETIME DEFAULT GETDATE()
);
GO

--  Audit Log table for Employee changes
CREATE TABLE EmployeeLog (
    LogID INT IDENTITY(1,1) PRIMARY KEY,
    EmployeeID INT NOT NULL,
    ActionType VARCHAR(20) NOT NULL CHECK (ActionType IN ('INSERT', 'UPDATE', 'DELETE')),
    ActionDateTime DATETIME NOT NULL DEFAULT GETDATE(),
    FieldName VARCHAR(100) NULL,
    OldValue NVARCHAR(500) NULL,
    NewValue NVARCHAR(500) NULL,
    ModifiedBy VARCHAR(100) NOT NULL
);
GO

--  Performance table to track employee evaluations
CREATE TABLE Performance (
    PerformanceID INT IDENTITY(1,1) PRIMARY KEY,
    EmployeeID INT NOT NULL FOREIGN KEY REFERENCES Employee(EmployeeID),
    ReviewPeriod VARCHAR(50) NOT NULL, -- E.g., "Q1 2025", "Annual 2024"
    ReviewDate DATE NOT NULL,
    PerformanceRating DECIMAL(3,2) NOT NULL CHECK (PerformanceRating BETWEEN 1 AND 5),
    Strengths NVARCHAR(500) NULL,
    AreasForImprovement NVARCHAR(500) NULL,
    Comments NVARCHAR(1000) NULL,
    ReviewedBy INT NOT NULL FOREIGN KEY REFERENCES Employee(EmployeeID),
    CreatedDate DATETIME DEFAULT GETDATE(),
    ModifiedDate DATETIME DEFAULT GETDATE()
);
GO

-- ========================================
-- SERVER-LEVEL SECURITY SETUP
-- ========================================

-- Create Login for Administrator
USE master;
GO

IF NOT EXISTS (SELECT name FROM sys.server_principals WHERE name = 'WIS_Admin')
BEGIN
    CREATE LOGIN WIS_Admin WITH PASSWORD = 'StrongPassword123!';
END
GO

-- Create Login for HR User
IF NOT EXISTS (SELECT name FROM sys.server_principals WHERE name = 'WIS_HR')
BEGIN
    CREATE LOGIN WIS_HR WITH PASSWORD = 'HRPassword456!';
END
GO

-- Create Login for Department Manager
IF NOT EXISTS (SELECT name FROM sys.server_principals WHERE name = 'WIS_Manager')
BEGIN
    CREATE LOGIN WIS_Manager WITH PASSWORD = 'ManagerPassword789!';
END
GO

-- Create Login for Regular Employee
IF NOT EXISTS (SELECT name FROM sys.server_principals WHERE name = 'WIS_Employee')
BEGIN
    CREATE LOGIN WIS_Employee WITH PASSWORD = 'EmployeePassword321!';
END
GO

USE WIS;
GO

-- Create Database Users
IF NOT EXISTS (SELECT name FROM sys.database_principals WHERE name = 'WIS_Admin')
BEGIN
    CREATE USER WIS_Admin FOR LOGIN WIS_Admin;
END
GO

IF NOT EXISTS (SELECT name FROM sys.database_principals WHERE name = 'WIS_HR')
BEGIN
    CREATE USER WIS_HR FOR LOGIN WIS_HR;
END
GO

IF NOT EXISTS (SELECT name FROM sys.database_principals WHERE name = 'WIS_Manager')
BEGIN
    CREATE USER WIS_Manager FOR LOGIN WIS_Manager;
END
GO

IF NOT EXISTS (SELECT name FROM sys.database_principals WHERE name = 'WIS_Employee')
BEGIN
    CREATE USER WIS_Employee FOR LOGIN WIS_Employee;
END
GO

-- Create Database Roles
IF NOT EXISTS (SELECT name FROM sys.database_principals WHERE name = 'WIS_AdminRole' AND type = 'R')
BEGIN
    CREATE ROLE WIS_AdminRole;
END
GO

IF NOT EXISTS (SELECT name FROM sys.database_principals WHERE name = 'WIS_HRRole' AND type = 'R')
BEGIN
    CREATE ROLE WIS_HRRole;
END
GO

IF NOT EXISTS (SELECT name FROM sys.database_principals WHERE name = 'WIS_ManagerRole' AND type = 'R')
BEGIN
    CREATE ROLE WIS_ManagerRole;
END
GO

IF NOT EXISTS (SELECT name FROM sys.database_principals WHERE name = 'WIS_EmployeeRole' AND type = 'R')
BEGIN
    CREATE ROLE WIS_EmployeeRole;
END
GO

-- Add Users to Roles
ALTER ROLE WIS_AdminRole ADD MEMBER WIS_Admin;
ALTER ROLE WIS_HRRole ADD MEMBER WIS_HR;
ALTER ROLE WIS_ManagerRole ADD MEMBER WIS_Manager;
ALTER ROLE WIS_EmployeeRole ADD MEMBER WIS_Employee;
GO

-- Grant Permissions to HR Role
GRANT CONTROL ON DATABASE::WIS TO WIS_AdminRole; 
GO

GRANT EXECUTE ON SCHEMA::dbo TO WIS_HRRole;
GO

GRANT SELECT, INSERT, UPDATE, DELETE ON [dbo].[Employee] TO WIS_HRRole;
GRANT SELECT, INSERT, UPDATE, DELETE ON [dbo].[Department] TO WIS_HRRole;
GRANT SELECT, INSERT, UPDATE, DELETE ON [dbo].[Position] TO WIS_HRRole;
GRANT SELECT, INSERT, UPDATE, DELETE ON [dbo].[Performance] TO WIS_HRRole;
GRANT SELECT ON [dbo].[EmployeeLog] TO WIS_HRRole;
GRANT SELECT ON [dbo].[vw_EmployeeInfo] TO WIS_HRRole;
GRANT SELECT ON [dbo].[vw_EmployeePerformance] TO WIS_HRRole;
GO

-- Grant Permissions to Manager Role
GRANT EXECUTE ON [dbo].[sp_GetEmployeeDetails] TO WIS_ManagerRole;
GRANT EXECUTE ON [dbo].[sp_GetEmployeesByDepartment] TO WIS_ManagerRole;
GRANT EXECUTE ON [dbo].[sp_GetEmployeesByPosition] TO WIS_ManagerRole;
GRANT EXECUTE ON [dbo].[sp_GetEmployeePerformanceHistory] TO WIS_ManagerRole;
GRANT EXECUTE ON [dbo].[sp_GetDepartments] TO WIS_ManagerRole;
GRANT EXECUTE ON [dbo].[sp_GetPositions] TO WIS_ManagerRole;
GRANT EXECUTE ON [dbo].[sp_InsertPerformance] TO WIS_ManagerRole;
GRANT EXECUTE ON [dbo].[sp_UpdatePerformance] TO WIS_ManagerRole;
GRANT SELECT ON [dbo].[vw_EmployeeInfo] TO WIS_ManagerRole;
GRANT SELECT ON [dbo].[vw_EmployeePerformance] TO WIS_ManagerRole;
GO

-- Deny sensitive operations to Manager Role
DENY EXECUTE ON [dbo].[sp_DeleteEmployee] TO WIS_ManagerRole;
DENY UPDATE ON [dbo].[Employee]([Salary]) TO WIS_ManagerRole;
GO

-- Grant Permissions to Employee Role
GRANT EXECUTE ON [dbo].[sp_GetEmployeeDetails] TO WIS_EmployeeRole;
GRANT EXECUTE ON [dbo].[sp_GetDepartments] TO WIS_EmployeeRole;
GRANT EXECUTE ON [dbo].[sp_GetPositions] TO WIS_EmployeeRole;
GO

-- Create view for employees to see their own performance
GO
CREATE VIEW vw_MyPerformance AS 
SELECT p.* 
FROM Performance p 
INNER JOIN Employee e ON p.EmployeeID = e.EmployeeID 
WHERE e.EmployeeID = CAST(SESSION_CONTEXT(N'EmployeeID') AS INT);
GO

-- Grant permissions on MyPerformance view
GRANT SELECT ON [dbo].[vw_MyPerformance] TO WIS_EmployeeRole;
GO

-- Procedure to set employee context for the session
GO
CREATE PROCEDURE sp_SetEmployeeContext 
    @EmployeeID INT 
AS 
BEGIN 
    SET NOCOUNT ON; 
    EXEC sp_set_session_context @key = N'EmployeeID', @value = @EmployeeID; 
END
GO

-- Grant EXECUTE on the procedure to Employee Role
GRANT EXECUTE ON [dbo].[sp_SetEmployeeContext] TO WIS_EmployeeRole;
GO

-- ========================================
-- AUDIT TRIGGERS SECTION
-- ========================================

-- Trigger for auditing INSERT operations on Employee table
CREATE TRIGGER trg_Employee_Insert
ON Employee
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ModifiedBy VARCHAR(100) = SYSTEM_USER;

    INSERT INTO EmployeeLog (EmployeeID, ActionType, FieldName, OldValue, NewValue, ModifiedBy)
    SELECT 
        i.EmployeeID, 
        'INSERT', 
        'Record', 
        NULL, 
        'Employee ID: ' + CAST(i.EmployeeID AS VARCHAR) + ', Name: ' + i.FirstName + ' ' + i.LastName, 
        @ModifiedBy
    FROM inserted i;
END;
GO

-- Trigger for auditing UPDATE operations on Employee table
CREATE TRIGGER trg_Employee_Update
ON Employee
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ModifiedBy VARCHAR(100) = SYSTEM_USER;  --SYSTEM_USER captures which database user made the change

    -- Insert log entries for each changed column
    INSERT INTO EmployeeLog (EmployeeID, ActionType, FieldName, OldValue, NewValue, ModifiedBy)
    SELECT 
        i.EmployeeID, 
        'UPDATE', 
        'FirstName', 
        d.FirstName, 
        i.FirstName, 
        @ModifiedBy
    FROM inserted i
    INNER JOIN deleted d ON i.EmployeeID = d.EmployeeID
    WHERE i.FirstName <> d.FirstName;

    INSERT INTO EmployeeLog (EmployeeID, ActionType, FieldName, OldValue, NewValue, ModifiedBy)
    SELECT 
        i.EmployeeID, 
        'UPDATE', 
        'LastName', 
        d.LastName, 
        i.LastName, 
        @ModifiedBy
    FROM inserted i
    INNER JOIN deleted d ON i.EmployeeID = d.EmployeeID
    WHERE i.LastName <> d.LastName;

    INSERT INTO EmployeeLog (EmployeeID, ActionType, FieldName, OldValue, NewValue, ModifiedBy)
    SELECT 
        i.EmployeeID, 
        'UPDATE', 
        'Email', 
        d.Email, 
        i.Email, 
        @ModifiedBy
    FROM inserted i
    INNER JOIN deleted d ON i.EmployeeID = d.EmployeeID
    WHERE i.Email <> d.Email;

    INSERT INTO EmployeeLog (EmployeeID, ActionType, FieldName, OldValue, NewValue, ModifiedBy)
    SELECT 
        i.EmployeeID, 
        'UPDATE', 
        'DepartmentID', 
        CAST(d.DepartmentID AS VARCHAR), 
        CAST(i.DepartmentID AS VARCHAR), 
        @ModifiedBy
    FROM inserted i
    INNER JOIN deleted d ON i.EmployeeID = d.EmployeeID
    WHERE i.DepartmentID <> d.DepartmentID;

    INSERT INTO EmployeeLog (EmployeeID, ActionType, FieldName, OldValue, NewValue, ModifiedBy)
    SELECT 
        i.EmployeeID, 
        'UPDATE', 
        'PositionID', 
        CAST(d.PositionID AS VARCHAR), 
        CAST(i.PositionID AS VARCHAR), 
        @ModifiedBy
    FROM inserted i
    INNER JOIN deleted d ON i.EmployeeID = d.EmployeeID
    WHERE i.PositionID <> d.PositionID;

    INSERT INTO EmployeeLog (EmployeeID, ActionType, FieldName, OldValue, NewValue, ModifiedBy)
    SELECT 
        i.EmployeeID, 
        'UPDATE', 
        'Status', 
        d.Status, 
        i.Status, 
        @ModifiedBy
    FROM inserted i
    INNER JOIN deleted d ON i.EmployeeID = d.EmployeeID
    WHERE i.Status <> d.Status;

    INSERT INTO EmployeeLog (EmployeeID, ActionType, FieldName, OldValue, NewValue, ModifiedBy)
    SELECT 
        i.EmployeeID, 
        'UPDATE', 
        'Salary', 
        CAST(d.Salary AS VARCHAR), 
        CAST(i.Salary AS VARCHAR), 
        @ModifiedBy
    FROM inserted i
    INNER JOIN deleted d ON i.EmployeeID = d.EmployeeID
    WHERE i.Salary <> d.Salary;
END;
GO

-- Trigger for auditing DELETE operations on Employee table
CREATE TRIGGER trg_Employee_Delete
ON Employee
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @ModifiedBy VARCHAR(100) = SYSTEM_USER;

    INSERT INTO EmployeeLog (EmployeeID, ActionType, FieldName, OldValue, NewValue, ModifiedBy)
    SELECT 
        d.EmployeeID, 
        'DELETE', 
        'Record', 
        'Employee ID: ' + CAST(d.EmployeeID AS VARCHAR) + ', Name: ' + d.FirstName + ' ' + d.LastName, 
        NULL, 
        @ModifiedBy
    FROM deleted d;
END;
GO

-- ========================================
-- VIEWS SECTION
-- ========================================

-- View for employee information with department and position names
CREATE VIEW vw_EmployeeInfo AS
SELECT 
    e.EmployeeID,
    e.EmployeeCode,
    e.FirstName,
    e.LastName,
    e.FirstName + ' ' + e.LastName AS FullName,
    e.Email,
    e.Phone,
    e.DepartmentID,
    d.DepartmentName,
    e.PositionID,
    p.PositionName,
    e.JoiningDate,
    e.Salary,
    e.Status,
    e.ReportsTo,
    m.FirstName + ' ' + m.LastName AS ManagerName
FROM Employee e
LEFT JOIN Department d ON e.DepartmentID = d.DepartmentID
LEFT JOIN Position p ON e.PositionID = p.PositionID
LEFT JOIN Employee m ON e.ReportsTo = m.EmployeeID;
GO

-- View for employee performance history
CREATE VIEW vw_EmployeePerformance AS
SELECT 
    p.PerformanceID,
    e.EmployeeID,
    e.FirstName + ' ' + e.LastName AS EmployeeName,
    p.ReviewPeriod,
    p.ReviewDate,
    p.PerformanceRating,
    p.Strengths,
    p.AreasForImprovement,
    p.Comments,
    r.FirstName + ' ' + r.LastName AS ReviewedByName
FROM Performance p
INNER JOIN Employee e ON p.EmployeeID = e.EmployeeID
INNER JOIN Employee r ON p.ReviewedBy = r.EmployeeID;
GO

-- ========================================
-- STORED PROCEDURES - DEPARTMENT MANAGEMENT
-- ========================================

-- Procedure to insert a new department
CREATE PROCEDURE sp_InsertDepartment
    @DepartmentName NVARCHAR(100),
    @Description NVARCHAR(500) = NULL,
    @DepartmentID INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        IF EXISTS (SELECT 1 FROM Department WHERE DepartmentName = @DepartmentName)
        BEGIN
            RAISERROR('Department with this name already exists.', 16, 1);
            RETURN;
        END
        
        INSERT INTO Department (DepartmentName, Description)
        VALUES (@DepartmentName, @Description);
        
        SET @DepartmentID = SCOPE_IDENTITY();
        
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
            
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH;
END;
GO

-- Procedure to update a department
CREATE PROCEDURE sp_UpdateDepartment
    @DepartmentID INT,
    @DepartmentName NVARCHAR(100),
    @Description NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        IF NOT EXISTS (SELECT 1 FROM Department WHERE DepartmentID = @DepartmentID)
        BEGIN
            RAISERROR('Department does not exist.', 16, 1);
            RETURN;
        END
        
        IF EXISTS (SELECT 1 FROM Department WHERE DepartmentName = @DepartmentName AND DepartmentID != @DepartmentID)
        BEGIN
            RAISERROR('Another department with this name already exists.', 16, 1);
            RETURN;
        END
        
        UPDATE Department
        SET DepartmentName = @DepartmentName,
            Description = @Description,
            ModifiedDate = GETDATE()
        WHERE DepartmentID = @DepartmentID;
        
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
            
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH;
END;
GO

-- Procedure to delete a department
CREATE PROCEDURE sp_DeleteDepartment
    @DepartmentID INT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        IF NOT EXISTS (SELECT 1 FROM Department WHERE DepartmentID = @DepartmentID)
        BEGIN
            RAISERROR('Department does not exist.', 16, 1);
            RETURN;
        END
        
        IF EXISTS (SELECT 1 FROM Employee WHERE DepartmentID = @DepartmentID)
        BEGIN
            RAISERROR('Cannot delete department. Employees are assigned to this department.', 16, 1);
            RETURN;
        END
        
        DELETE FROM Department
        WHERE DepartmentID = @DepartmentID;
        
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
            
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH;
END;
GO

-- ========================================
-- STORED PROCEDURES - POSITION MANAGEMENT
-- ========================================

-- Procedure to insert a new position
CREATE PROCEDURE sp_InsertPosition
    @PositionName NVARCHAR(100),
    @Description NVARCHAR(500) = NULL,
    @PayGrade VARCHAR(20) = NULL,
    @PositionID INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        IF EXISTS (SELECT 1 FROM Position WHERE PositionName = @PositionName)
        BEGIN
            RAISERROR('Position with this name already exists.', 16, 1);
            RETURN;
        END
        
        INSERT INTO Position (PositionName, Description, PayGrade)
        VALUES (@PositionName, @Description, @PayGrade);
        
        SET @PositionID = SCOPE_IDENTITY();
        
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
            
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH;
END;
GO

-- Procedure to update a position
CREATE PROCEDURE sp_UpdatePosition
    @PositionID INT,
    @PositionName NVARCHAR(100),
    @Description NVARCHAR(500) = NULL,
    @PayGrade VARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        IF NOT EXISTS (SELECT 1 FROM Position WHERE PositionID = @PositionID)
        BEGIN
            RAISERROR('Position does not exist.', 16, 1);
            RETURN;
        END
        
        IF EXISTS (SELECT 1 FROM Position WHERE PositionName = @PositionName AND PositionID != @PositionID)
        BEGIN
            RAISERROR('Another position with this name already exists.', 16, 1);
            RETURN;
        END
        
        UPDATE Position
        SET PositionName = @PositionName,
            Description = @Description,
            PayGrade = @PayGrade,
            ModifiedDate = GETDATE()
        WHERE PositionID = @PositionID;
        
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
            
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH;
END;
GO

-- Procedure to delete a position
CREATE PROCEDURE sp_DeletePosition
    @PositionID INT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        IF NOT EXISTS (SELECT 1 FROM Position WHERE PositionID = @PositionID)
        BEGIN
            RAISERROR('Position does not exist.', 16, 1);
            RETURN;
        END
        
        IF EXISTS (SELECT 1 FROM Employee WHERE PositionID = @PositionID)
        BEGIN
            RAISERROR('Cannot delete position. Employees are assigned to this position.', 16, 1);
            RETURN;
        END
        
        DELETE FROM Position
        WHERE PositionID = @PositionID;
        
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
            
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH;
END;


-- ========================================
-- STORED PROCEDURES - EMPLOYEE MANAGEMENT
-- ========================================

-- Procedure to insert a new employee
CREATE PROCEDURE sp_InsertEmployee
    @EmployeeCode VARCHAR(20),
    @FirstName NVARCHAR(50),
    @LastName NVARCHAR(50),
    @Email NVARCHAR(100),
    @Phone VARCHAR(20) = NULL,
    @DepartmentID INT,
    @PositionID INT,
    @JoiningDate DATE,
    @Salary DECIMAL(18,2),
    @Status VARCHAR(20) = 'Active',
    @ReportsTo INT = NULL,
    @EmployeeID INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Validate input
        IF NOT EXISTS (SELECT 1 FROM Department WHERE DepartmentID = @DepartmentID)
        BEGIN
            RAISERROR('Invalid department ID.', 16, 1);
            RETURN;
        END
        
        IF NOT EXISTS (SELECT 1 FROM Position WHERE PositionID = @PositionID)
        BEGIN
            RAISERROR('Invalid position ID.', 16, 1);
            RETURN;
        END
        
        IF @ReportsTo IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Employee WHERE EmployeeID = @ReportsTo)
        BEGIN
            RAISERROR('Invalid manager ID.', 16, 1);
            RETURN;
        END
        
        IF EXISTS (SELECT 1 FROM Employee WHERE EmployeeCode = @EmployeeCode)
        BEGIN
            RAISERROR('Employee with this code already exists.', 16, 1);
            RETURN;
        END
        
        IF EXISTS (SELECT 1 FROM Employee WHERE Email = @Email)
        BEGIN
            RAISERROR('Employee with this email already exists.', 16, 1);
            RETURN;
        END
        
        -- Insert employee record
        INSERT INTO Employee (
            EmployeeCode, FirstName, LastName, Email, Phone, 
            DepartmentID, PositionID, JoiningDate, Salary, Status, ReportsTo
        )
        VALUES (
            @EmployeeCode, @FirstName, @LastName, @Email, @Phone,
            @DepartmentID, @PositionID, @JoiningDate, @Salary, @Status, @ReportsTo
        );
        
        SET @EmployeeID = SCOPE_IDENTITY();
        
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
            
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH;
END;
GO

-- Procedure to update an employee
CREATE PROCEDURE sp_UpdateEmployee
    @EmployeeID INT,
    @EmployeeCode VARCHAR(20) = NULL,
    @FirstName NVARCHAR(50) = NULL,
    @LastName NVARCHAR(50) = NULL,
    @Email NVARCHAR(100) = NULL,
    @Phone VARCHAR(20) = NULL,
    @DepartmentID INT = NULL,
    @PositionID INT = NULL,
    @JoiningDate DATE = NULL,
    @Salary DECIMAL(18,2) = NULL,
    @Status VARCHAR(20) = NULL,
    @ReportsTo INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Check if employee exists
        IF NOT EXISTS (SELECT 1 FROM Employee WHERE EmployeeID = @EmployeeID)
        BEGIN
            RAISERROR('Employee does not exist.', 16, 1);
            RETURN;
        END
        
        -- Get current values if parameters are NULL
        DECLARE 
            @CurrentEmployeeCode VARCHAR(20),
            @CurrentFirstName NVARCHAR(50),
            @CurrentLastName NVARCHAR(50),
            @CurrentEmail NVARCHAR(100),
            @CurrentPhone VARCHAR(20),
            @CurrentDepartmentID INT,
            @CurrentPositionID INT,
            @CurrentJoiningDate DATE,
            @CurrentSalary DECIMAL(18,2),
            @CurrentStatus VARCHAR(20),
            @CurrentReportsTo INT;
            
        SELECT 
            @CurrentEmployeeCode = EmployeeCode,
            @CurrentFirstName = FirstName,
            @CurrentLastName = LastName,
            @CurrentEmail = Email,
            @CurrentPhone = Phone,
            @CurrentDepartmentID = DepartmentID,
            @CurrentPositionID = PositionID,
            @CurrentJoiningDate = JoiningDate,
            @CurrentSalary = Salary,
            @CurrentStatus = Status,
            @CurrentReportsTo = ReportsTo
        FROM Employee
        WHERE EmployeeID = @EmployeeID;
        
        -- Use provided values or current values
        SET @EmployeeCode = ISNULL(@EmployeeCode, @CurrentEmployeeCode);
        SET @FirstName = ISNULL(@FirstName, @CurrentFirstName);
        SET @LastName = ISNULL(@LastName, @CurrentLastName);
        SET @Email = ISNULL(@Email, @CurrentEmail);
        SET @Phone = ISNULL(@Phone, @CurrentPhone);
        SET @DepartmentID = ISNULL(@DepartmentID, @CurrentDepartmentID);
        SET @PositionID = ISNULL(@PositionID, @CurrentPositionID);
        SET @JoiningDate = ISNULL(@JoiningDate, @CurrentJoiningDate);
        SET @Salary = ISNULL(@Salary, @CurrentSalary);
        SET @Status = ISNULL(@Status, @CurrentStatus);
        SET @ReportsTo = ISNULL(@ReportsTo, @CurrentReportsTo);
        
        -- Validate input
        IF NOT EXISTS (SELECT 1 FROM Department WHERE DepartmentID = @DepartmentID)
        BEGIN
            RAISERROR('Invalid department ID.', 16, 1);
            RETURN;
        END
        
        IF NOT EXISTS (SELECT 1 FROM Position WHERE PositionID = @PositionID)
        BEGIN
            RAISERROR('Invalid position ID.', 16, 1);
            RETURN;
        END
        
        IF @ReportsTo IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Employee WHERE EmployeeID = @ReportsTo)
        BEGIN
            RAISERROR('Invalid manager ID.', 16, 1);
            RETURN;
        END
        
        IF EXISTS (SELECT 1 FROM Employee WHERE EmployeeCode = @EmployeeCode AND EmployeeID != @EmployeeID)
        BEGIN
            RAISERROR('Another employee with this code already exists.', 16, 1);
            RETURN;
        END
        
        IF EXISTS (SELECT 1 FROM Employee WHERE Email = @Email AND EmployeeID != @EmployeeID)
        BEGIN
            RAISERROR('Another employee with this email already exists.', 16, 1);
            RETURN;
        END
        
        -- Update employee record
        UPDATE Employee
        SET EmployeeCode = @EmployeeCode,
            FirstName = @FirstName,
            LastName = @LastName,
            Email = @Email,
            Phone = @Phone,
            DepartmentID = @DepartmentID,
            PositionID = @PositionID,
            JoiningDate = @JoiningDate,
            Salary = @Salary,
            Status = @Status,
            ReportsTo = @ReportsTo,
            ModifiedDate = GETDATE()
        WHERE EmployeeID = @EmployeeID;
        
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
            
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH;
END;
GO

-- Procedure to delete an employee
CREATE PROCEDURE sp_DeleteEmployee
    @EmployeeID INT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        IF NOT EXISTS (SELECT 1 FROM Employee WHERE EmployeeID = @EmployeeID)
        BEGIN
            RAISERROR('Employee does not exist.', 16, 1);
            RETURN;
        END
        
        -- Check if the employee is a manager to other employees
        IF EXISTS (SELECT 1 FROM Employee WHERE ReportsTo = @EmployeeID)
        BEGIN
            RAISERROR('Cannot delete employee. This employee is assigned as a manager to other employees.', 16, 1);
            RETURN;
        END
        
        -- Check if employee has performance records
        IF EXISTS (SELECT 1 FROM Performance WHERE EmployeeID = @EmployeeID OR ReviewedBy = @EmployeeID)
        BEGIN
            RAISERROR('Cannot delete employee. This employee has performance records or has reviewed other employees.', 16, 1);
            RETURN;
        END
        
        DELETE FROM Employee
        WHERE EmployeeID = @EmployeeID;
        
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
            
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH;
END;
GO

-- ========================================
-- STORED PROCEDURES - PERFORMANCE MANAGEMENT
-- ========================================

-- Procedure to insert a new performance record
CREATE PROCEDURE sp_InsertPerformance
    @EmployeeID INT,
    @ReviewPeriod VARCHAR(50),
    @ReviewDate DATE,
    @PerformanceRating DECIMAL(3,2),
    @Strengths NVARCHAR(500) = NULL,
    @AreasForImprovement NVARCHAR(500) = NULL,
    @Comments NVARCHAR(1000) = NULL,
    @ReviewedBy INT,
    @PerformanceID INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Validate input
        IF NOT EXISTS (SELECT 1 FROM Employee WHERE EmployeeID = @EmployeeID)
        BEGIN
            RAISERROR('Invalid employee ID.', 16, 1);
            RETURN;
        END
        
        IF NOT EXISTS (SELECT 1 FROM Employee WHERE EmployeeID = @ReviewedBy)
        BEGIN
            RAISERROR('Invalid reviewer ID.', 16, 1);
            RETURN;
        END
        
        -- Check if a performance record already exists for this employee and review period
        IF EXISTS (SELECT 1 FROM Performance WHERE EmployeeID = @EmployeeID AND ReviewPeriod = @ReviewPeriod)
        BEGIN
            RAISERROR('A performance record for this employee and review period already exists.', 16, 1);
            RETURN;
        END
        
        -- Insert performance record
        INSERT INTO Performance (
            EmployeeID, ReviewPeriod, ReviewDate, PerformanceRating,
            Strengths, AreasForImprovement, Comments, ReviewedBy
        )
        VALUES (
            @EmployeeID, @ReviewPeriod, @ReviewDate, @PerformanceRating,
            @Strengths, @AreasForImprovement, @Comments, @ReviewedBy
        );
        
        SET @PerformanceID = SCOPE_IDENTITY();
        
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
            
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH;
END;
GO

-- Procedure to update a performance record
CREATE PROCEDURE sp_UpdatePerformance
    @PerformanceID INT,
    @PerformanceRating DECIMAL(3,2) = NULL,
    @Strengths NVARCHAR(500) = NULL,
    @AreasForImprovement NVARCHAR(500) = NULL,
    @Comments NVARCHAR(1000) = NULL,
    @ReviewedBy INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
       -- Check if performance record exists
        IF NOT EXISTS (SELECT 1 FROM Performance WHERE PerformanceID = @PerformanceID)
        BEGIN
            RAISERROR('Performance record does not exist.', 16, 1);
            RETURN;
        END
        
        DECLARE 
            @CurrentPerformanceRating DECIMAL(3,2),
            @CurrentStrengths NVARCHAR(500),
            @CurrentAreasForImprovement NVARCHAR(500),
            @CurrentComments NVARCHAR(1000),
            @CurrentReviewedBy INT;
        
        -- Get current values
        SELECT 
            @CurrentPerformanceRating = PerformanceRating,
            @CurrentStrengths = Strengths,
            @CurrentAreasForImprovement = AreasForImprovement,
            @CurrentComments = Comments,
            @CurrentReviewedBy = ReviewedBy
        FROM Performance
        WHERE PerformanceID = @PerformanceID;
        
        -- Use provided values or current values
        SET @PerformanceRating = ISNULL(@PerformanceRating, @CurrentPerformanceRating);
        SET @Strengths = ISNULL(@Strengths, @CurrentStrengths);
        SET @AreasForImprovement = ISNULL(@AreasForImprovement, @CurrentAreasForImprovement);
        SET @Comments = ISNULL(@Comments, @CurrentComments);
        SET @ReviewedBy = ISNULL(@ReviewedBy, @CurrentReviewedBy);
        
        -- Validate reviewer
        IF NOT EXISTS (SELECT 1 FROM Employee WHERE EmployeeID = @ReviewedBy)
        BEGIN
            RAISERROR('Invalid reviewer ID.', 16, 1);
            RETURN;
        END
        
        -- Update performance record
        UPDATE Performance
        SET PerformanceRating = @PerformanceRating,
            Strengths = @Strengths,
            AreasForImprovement = @AreasForImprovement,
            Comments = @Comments,
            ReviewedBy = @ReviewedBy,
            ModifiedDate = GETDATE()
        WHERE PerformanceID = @PerformanceID;
        
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
            
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH;
END;
GO

-- Procedure to delete a performance record
CREATE PROCEDURE sp_DeletePerformance
    @PerformanceID INT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        IF NOT EXISTS (SELECT 1 FROM Performance WHERE PerformanceID = @PerformanceID)
        BEGIN
            RAISERROR('Performance record does not exist.', 16, 1);
            RETURN;
        END
        
        DELETE FROM Performance
        WHERE PerformanceID = @PerformanceID;
        
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
            
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH;
END;
GO

-- ========================================
-- DATA RETRIEVAL PROCEDURES
-- ========================================

-- Procedure to get employee details with department and position
CREATE PROCEDURE sp_GetEmployeeDetails
    @EmployeeID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    IF @EmployeeID IS NULL
        SELECT * FROM vw_EmployeeInfo ORDER BY DepartmentName, PositionName, LastName, FirstName;
    ELSE
        SELECT * FROM vw_EmployeeInfo WHERE EmployeeID = @EmployeeID;
END;
GO

-- Procedure to get employees by department
CREATE PROCEDURE sp_GetEmployeesByDepartment
    @DepartmentID INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT * FROM vw_EmployeeInfo 
    WHERE DepartmentID = @DepartmentID
    ORDER BY PositionName, LastName, FirstName;
END;
GO

-- Procedure to get employees by position
CREATE PROCEDURE sp_GetEmployeesByPosition
    @PositionID INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT * FROM vw_EmployeeInfo 
    WHERE PositionID = @PositionID
    ORDER BY DepartmentName, LastName, FirstName;
END;
GO

-- Procedure to get employee performance history
CREATE PROCEDURE sp_GetEmployeePerformanceHistory
    @EmployeeID INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT * FROM vw_EmployeePerformance
    WHERE EmployeeID = @EmployeeID
    ORDER BY ReviewDate DESC;
END;
GO

-- Procedure to get department list
CREATE PROCEDURE sp_GetDepartments
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT * FROM Department ORDER BY DepartmentName;
END;
GO

-- Procedure to get position list
CREATE PROCEDURE sp_GetPositions
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT * FROM Position ORDER BY PositionName;
END;
GO

-- Procedure to get audit logs for employee
CREATE PROCEDURE sp_GetEmployeeAuditLogs
    @EmployeeID INT = NULL,
    @StartDate DATETIME = NULL,
    @EndDate DATETIME = NULL,
    @ActionType VARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        el.LogID,
        el.EmployeeID,
        e.FirstName + ' ' + e.LastName AS EmployeeName,
        el.ActionType,
        el.ActionDateTime,
        el.FieldName,
        el.OldValue,
        el.NewValue,
        el.ModifiedBy
    FROM EmployeeLog el
    JOIN Employee e ON el.EmployeeID = e.EmployeeID
    WHERE (@EmployeeID IS NULL OR el.EmployeeID = @EmployeeID)
        AND (@StartDate IS NULL OR el.ActionDateTime >= @StartDate)
        AND (@EndDate IS NULL OR el.ActionDateTime <= @EndDate)
        AND (@ActionType IS NULL OR el.ActionType = @ActionType)
    ORDER BY el.ActionDateTime DESC;
END;
GO


-- ========================================
-- SAMPLE DATA INSERTION
-- ========================================

-- Insert Departments
DECLARE @DeptID INT;
EXEC sp_InsertDepartment 'Human Resources', 'Manages employee relations and hiring', @DeptID OUTPUT;
EXEC sp_InsertDepartment 'Information Technology', 'Manages IT infrastructure and software development', @DeptID OUTPUT;
EXEC sp_InsertDepartment 'Finance', 'Manages company finances and accounting', @DeptID OUTPUT;
EXEC sp_InsertDepartment 'Marketing', 'Handles company branding and product promotion', @DeptID OUTPUT;
EXEC sp_InsertDepartment 'Operations', 'Oversees daily business operations', @DeptID OUTPUT;
GO

-- Insert Positions
DECLARE @PosID INT;
EXEC sp_InsertPosition 'HR Manager', 'Leads the HR department', 'G5', @PosID OUTPUT;
EXEC sp_InsertPosition 'HR Officer', 'Handles HR operations', 'G3', @PosID OUTPUT;
EXEC sp_InsertPosition 'IT Director', 'Oversees all IT operations', 'G6', @PosID OUTPUT;
EXEC sp_InsertPosition 'Software Developer', 'Develops software applications', 'G4', @PosID OUTPUT;
EXEC sp_InsertPosition 'Network Administrator', 'Manages network infrastructure', 'G4', @PosID OUTPUT;
EXEC sp_InsertPosition 'Finance Director', 'Leads financial operations', 'G6', @PosID OUTPUT;
EXEC sp_InsertPosition 'Accountant', 'Handles accounting tasks', 'G3', @PosID OUTPUT;
EXEC sp_InsertPosition 'Marketing Director', 'Leads marketing activities', 'G6', @PosID OUTPUT;
EXEC sp_InsertPosition 'Marketing Specialist', 'Executes marketing campaigns', 'G3', @PosID OUTPUT;
EXEC sp_InsertPosition 'Operations Manager', 'Manages company operations', 'G5', @PosID OUTPUT;
GO

-- Insert Employees
DECLARE @EmpID INT;

-- HR Department
EXEC sp_InsertEmployee 'EMP1001', 'Mr', 'Ali', 'ali@company.com', '555-123-4567', 1, 1, '2020-01-15', 75000.00, 'Active', NULL, @EmpID OUTPUT;
EXEC sp_InsertEmployee 'EMP1002', 'Ms', 'Sara', 'sarah@company.com', '555-234-5678', 1, 2, '2020-03-10', 48000.00, 'Active', @EmpID, @EmpID OUTPUT;

-- IT Department
EXEC sp_InsertEmployee 'EMP1003', 'IQ', 'Jaf', 'iq@company.com', '555-345-6789', 2, 3, '2019-05-20', 85000.00, 'Active', NULL, @EmpID OUTPUT;
DECLARE @ITDirectorID INT = @EmpID;
EXEC sp_InsertEmployee 'EMP1004', 'Ms', 'Alia', 'Alia@company.com', '555-456-7890', 2, 4, '2020-11-05', 65000.00, 'Active', @ITDirectorID, @EmpID OUTPUT;
EXEC sp_InsertEmployee 'EMP1005', 'Mr', 'Rehan', 'robert.wilson@company.com', '555-567-8901', 2, 5, '2021-02-15', 62000.00, 'Active', @ITDirectorID, @EmpID OUTPUT;

-- Finance Department
EXEC sp_InsertEmployee 'EMP1006', 'Ms', 'Anila', 'Anila@company.com', '555-678-9012', 3, 6, '2018-06-10', 82000.00, 'Active', NULL, @EmpID OUTPUT;
DECLARE @FinanceDirectorID INT = @EmpID;
EXEC sp_InsertEmployee 'EMP1007', 'Mr', 'Daniyal', 'Daniyal@company.com', '555-789-0123', 3, 7, '2021-07-01', 52000.00, 'Active', @FinanceDirectorID, @EmpID OUTPUT;

-- Marketing Department
EXEC sp_InsertEmployee 'EMP1008', 'Mr', 'Haseeb', 'Haseeb@company.com', '555-890-1234', 4, 8, '2019-08-15', 78000.00, 'Active', NULL, @EmpID OUTPUT;
DECLARE @MarketingDirectorID INT = @EmpID;
EXEC sp_InsertEmployee 'EMP1009', 'Ms', 'Alina', 'Alina@company.com', '555-901-2345', 4, 9, '2022-01-10', 48000.00, 'Active', @MarketingDirectorID, @EmpID OUTPUT;

-- Operations Department
EXEC sp_InsertEmployee 'EMP1010', 'Ms', 'Hina', 'Hina@company.com', '555-012-3456', 5, 10, '2019-03-05', 72000.00, 'Active', NULL, @EmpID OUTPUT;
GO

-- Insert Performance Records
DECLARE @PerfID INT;

-- HR Department
EXEC sp_InsertPerformance 1000, 'Annual 2023', '2023-12-15', 4.5, 'Excellent leadership skills, good team management', 'Could improve on documentation', ' has been an excellent manager leading the HR department effectively.', 1000, @PerfID OUTPUT;
EXEC sp_InsertPerformance 1001, 'Annual 2023', '2023-12-15', 4.2, 'Good communication, efficient with processes', 'Could be more proactive', 'Sarah has performed very well this year handling multiple HR initiatives.', 1000, @PerfID OUTPUT;

-- IT Department
EXEC sp_InsertPerformance 1002, 'Annual 2023', '2023-12-20', 4.7, 'Strong technical leadership, good project management', 'Could delegate more tasks', ' has successfully led several key IT projects this year.', 1000, @PerfID OUTPUT;
EXEC sp_InsertPerformance 1003, 'Annual 2023', '2023-12-20', 4.3, 'Excellent coding skills, meets deadlines', 'Could improve documentation', ' delivers high-quality code consistently.', 1002, @PerfID OUTPUT;
EXEC sp_InsertPerformance 1004, 'Annual 2023', '2023-12-20', 4.0, 'Good network management, responsive to issues', 'Could improve documentation of procedures', ' has maintained excellent network uptime.', 1002, @PerfID OUTPUT;

-- Finance Department
EXEC sp_InsertPerformance 1005, 'Annual 2023', '2023-12-10', 4.6, 'Strong financial leadership, good forecasting', 'Could communicate more with other departments', ' has led the finance team effectively through budget planning.', 1000, @PerfID OUTPUT;
EXEC sp_InsertPerformance 1006, 'Annual 2023', '2023-12-10', 4.1, 'Accurate accounting, good attention to detail', 'Could be more proactive with suggestions', ' maintains excellent accuracy in financial reporting.', 1005, @PerfID OUTPUT;

-- Marketing Department
EXEC sp_InsertPerformance 1007, 'Annual 2023', '2023-12-05', 4.4, 'Creative campaign ideas, good leadership', 'Could improve budget management', ' has led successful marketing campaigns this year.', 1000, @PerfID OUTPUT;
EXEC sp_InsertPerformance 1008, 'Annual 2023', '2023-12-05', 3.9, 'Good social media management, creative content', 'Could improve analytical skills', ' has grown our social media presence significantly.', 1007, @PerfID OUTPUT;

-- Operations Department
EXEC sp_InsertPerformance 1009, 'Annual 2023', '2023-12-01', 4.5, 'Excellent process optimization, good team management', 'Could improve documentation', ' has streamlined several key operational processes.', 1000, @PerfID OUTPUT;
GO

--performance operations
-- Add mid-year 2023 and Q1 2024 performance reviews for select employees
DECLARE @PerfID INT;

--  (HR Manager) - showing improvement
EXEC sp_InsertPerformance 1000, 'Mid-Year 2023', '2023-06-15', 4.0, 'Good leadership', 'Needs to improve documentation', ' performing well.', 1000, @PerfID OUTPUT;
EXEC sp_InsertPerformance 1000, 'Q1 2024', '2024-03-15', 4.7, 'Excellent leadership and improved documentation', 'Could mentor more junior staff', ' has shown consistent improvement.', 1000, @PerfID OUTPUT;

--  (HR Officer) - showing consistent performance
EXEC sp_InsertPerformance 1001, 'Mid-Year 2023', '2023-06-15', 4.0, 'Reliable and efficient', 'Could be more innovative', ' handles her responsibilities well.', 1000, @PerfID OUTPUT;
EXEC sp_InsertPerformance 1001, 'Q1 2024', '2024-03-15', 4.3, 'More proactive in process improvements', 'Could develop leadership skills', 'She is growing in her role.', 1000, @PerfID OUTPUT;

--  (IT Director) - showing slight decline
EXEC sp_InsertPerformance 1002, 'Mid-Year 2023', '2023-06-20', 4.8, 'Outstanding project delivery', 'Minor communication issues', ' consistently delivers excellent results.', 1000, @PerfID OUTPUT;
EXEC sp_InsertPerformance 1002, 'Q1 2024', '2024-03-20', 4.5, 'Good technical leadership', 'Challenged with new project scope', '  handling increasing pressures well.', 1000, @PerfID OUTPUT;

-- (Software Developer) - showing significant improvement
EXEC sp_InsertPerformance 1003, 'Mid-Year 2023', '2023-06-20', 3.8, 'Good coding skills', 'Documentation needs improvement', ' meets expectations.', 1002, @PerfID OUTPUT;
EXEC sp_InsertPerformance 1003, 'Q1 2024', '2024-03-20', 4.5, 'Excellent code quality and improved documentation', 'Could mentor junior developers', ' has shown remarkable improvement.', 1002, @PerfID OUTPUT;
-- Query to test the database
SELECT * FROM vw_EmployeeInfo;
SELECT * FROM vw_EmployeePerformance;
GO
--TEST QUERIES
SELECT d.DepartmentName, COUNT(e.EmployeeID) AS EmployeeCount
FROM Department d
LEFT JOIN Employee e ON d.DepartmentID = e.DepartmentID
GROUP BY d.DepartmentName;



-- 3. Employee Detail Report
SELECT e.EmployeeCode, e.FirstName, e.LastName, d.DepartmentName, p.PositionName
FROM Employee e
JOIN Department d ON e.DepartmentID = d.DepartmentID
JOIN Position p ON e.PositionID = p.PositionID;

---SHOWWWW  1. Employee Hierarchy Query (Modified)
WITH EmployeeHierarchy AS (
    -- Base case: employees who don't report to anyone (top level)
    SELECT EmployeeID, FirstName, LastName, ReportsTo, 0 AS Level
    FROM Employee
    WHERE ReportsTo IS NULL
    
    UNION ALL
    
    -- Recursive case: employees who report to someone
    SELECT e.EmployeeID, e.FirstName, e.LastName, e.ReportsTo, eh.Level + 1
    FROM Employee e
    INNER JOIN EmployeeHierarchy eh ON e.ReportsTo = eh.EmployeeID
)
SELECT 
    eh.EmployeeID,
    REPLICATE('    ', eh.Level) + eh.FirstName + ' ' + eh.LastName AS EmployeeHierarchy,
    d.DepartmentName,
    p.PositionName
FROM EmployeeHierarchy eh
JOIN Employee e ON eh.EmployeeID = e.EmployeeID
JOIN Department d ON e.DepartmentID = d.DepartmentID
JOIN Position p ON e.PositionID = p.PositionID
ORDER BY eh.Level, eh.LastName;

--2. Department Performance Analysis (Should Work As-Is)
SELECT 
    d.DepartmentName,
    COUNT(p.PerformanceID) AS ReviewCount,
    AVG(p.PerformanceRating) AS AvgRating,
    MIN(p.PerformanceRating) AS MinRating,
    MAX(p.PerformanceRating) AS MaxRating
FROM Department d
LEFT JOIN Employee e ON d.DepartmentID = e.DepartmentID
LEFT JOIN Performance p ON e.EmployeeID = p.EmployeeID
GROUP BY d.DepartmentName
ORDER BY AVG(p.PerformanceRating) DESC;
--3. Salary Distribution Analysis (Modified for SQL Server Compatibility)
SELECT 
    d.DepartmentName,
    COUNT(e.EmployeeID) AS EmployeeCount,
    AVG(e.Salary) AS AvgSalary,
    MIN(e.Salary) AS MinSalary,
    MAX(e.Salary) AS MaxSalary,
    STDEV(e.Salary) AS SalaryStdDev
FROM Department d
LEFT JOIN Employee e ON d.DepartmentID = e.DepartmentID
WHERE e.EmployeeID IS NOT NULL -- Add this to avoid STDEV calculation errors
GROUP BY d.DepartmentName
ORDER BY AVG(e.Salary) DESC;
--4. Audit Log Demonstration (Modified to Match Your Data)
-- First, make a change to trigger the audit log
UPDATE Employee SET Salary = Salary * 1.05 WHERE EmployeeID = 1000;

-- Then query the log
SELECT 
    el.ActionDateTime,
    e.FirstName + ' ' + e.LastName AS EmployeeName,
    el.FieldName,
    el.OldValue AS OldSalary,
    el.NewValue AS NewSalary,
    el.ModifiedBy
FROM EmployeeLog el
JOIN Employee e ON el.EmployeeID = e.EmployeeID
WHERE el.FieldName = 'Salary'
ORDER BY el.ActionDateTime DESC;

--5. Employee Tenure Report (Modified for Older SQL Server)
SELECT 
    e.EmployeeID,
    e.FirstName + ' ' + e.LastName AS EmployeeName,
    d.DepartmentName,
    p.PositionName,
    e.JoiningDate,
    DATEDIFF(MONTH, e.JoiningDate, GETDATE()) AS TenureMonths,
    '$' + CONVERT(VARCHAR, e.Salary, 1) AS CurrentSalary
FROM Employee e
JOIN Department d ON e.DepartmentID = d.DepartmentID
JOIN Position p ON e.PositionID = p.PositionID
ORDER BY e.JoiningDate;
--6. Cross-Department Performance Comparison (Should Work As-Is)
WITH DepartmentPerformance AS (
    SELECT 
        d.DepartmentID,
        d.DepartmentName,
        AVG(p.PerformanceRating) AS AvgPerformance
    FROM Department d
    JOIN Employee e ON d.DepartmentID = e.DepartmentID
    JOIN Performance p ON e.EmployeeID = p.EmployeeID
    GROUP BY d.DepartmentID, d.DepartmentName
)
SELECT 
    dp.DepartmentName,
    dp.AvgPerformance,
    (SELECT AVG(PerformanceRating) FROM Performance) AS CompanyAvgPerformance,
    CASE 
        WHEN dp.AvgPerformance > (SELECT AVG(PerformanceRating) FROM Performance) 
        THEN 'Above Average' 
        ELSE 'Below Average' 
    END AS PerformanceStatus
FROM DepartmentPerformance dp
ORDER BY dp.AvgPerformance DESC;
--7. Employee Performance Trend Analysis (Modified for SQL Server 2012+)
SELECT 
    e.EmployeeID,
    e.FirstName + ' ' + e.LastName AS EmployeeName,
    p.ReviewPeriod,
    p.ReviewDate,
    p.PerformanceRating,
    AVG(p.PerformanceRating) OVER(PARTITION BY e.EmployeeID) AS AvgRating
FROM Employee e
JOIN Performance p ON e.EmployeeID = p.EmployeeID
ORDER BY e.EmployeeID, p.ReviewDate;

--ROLES CHECKING
-- Step 1: Simulate login as WISS_Employee
EXECUTE AS USER = 'WIS_Employee';

-- Step 2: Try to perform an unauthorized action
DELETE FROM dbo.Employee WHERE EmployeeID = 1;  -- This should FAIL 

-- Step 3: Revert back to your original permissions
REVERT;

--To check the original user 
-- 1. Check original login (never changes)
SELECT ORIGINAL_LOGIN() AS 'Original_Login';

-- 2. Impersonate a user
EXECUTE AS USER = 'WIS_Employee';
SELECT USER_NAME() AS 'Current_User';  -- Shows 'WIS_Employee'

-- 3. Check original login again (still unchanged)
SELECT ORIGINAL_LOGIN() AS 'Original_Login';

-- 4. Revert back
REVERT;
SELECT USER_NAME() AS 'Current_User';  -- Back to original
--to check which is logged in user
	SELECT 
    USER_NAME() AS 'Current_Database_User',
    SUSER_NAME() AS 'SQL_Server_Login',
    ORIGINAL_LOGIN() AS 'Original_Login';
--2
-- Step 1: Simulate login as WISS_Manager
EXECUTE AS USER = 'WIS_Manager';

-- Step 2: Allowed action (can insert performance records)
EXEC dbo.sp_InsertPerformance @EmployeeID = 2, @ReviewDate = '2024-01-01', @PerformanceScore = 'Excellent'; -- Should work 

-- Step 3: Not allowed action (trying to delete employee)
EXEC dbo.sp_DeleteEmployee @EmployeeID = 2;  -- Should FAIL

-- Step 4: Come back to your original session
REVERT;

--3
-- Step 1: Simulate login as WISS_HR
EXECUTE AS USER = 'WIS_HR';

-- Step 2: Allowed action (HR can modify employee details)
UPDATE dbo.Employee SET Salary = 60000 WHERE EmployeeID = 2;  -- Should work

-- Step 3: NOT ALLOWED action (trying to execute a restricted procedure)
EXEC dbo.sp_DeleteEmployee @EmployeeID = 2;  -- This should FAIL 

-- Step 4: Come back to your original session
REVERT;
