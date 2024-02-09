USE [Car_Sales]
GO
/****** Object:  UserDefinedFunction [dbo].[GetAdditionalCommission]    Script Date: 09-02-2024 7.06.50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[GetAdditionalCommission](@SalesPersonID as int)
returns decimal(18,2)
as
begin


	declare @AdditionalCommission decimal(18,2) = 0
	declare @LastYearSale decimal(18,2) = (select LastYearTotalSale from LastYearSales where SalesPersonID = @SalesPersonID)
	declare @overAllSalesAmount decimal(18,2) = 0

	declare @AudiBrandID int = 0
	declare @JaguarBrandID int = 0
	declare @RoverBrandID int = 0
	declare @RenaultBrandID int = 0

	select @AudiBrandID = ID from BrandMaster where BrandName = 'Audi'
	select @JaguarBrandID = ID from BrandMaster where BrandName = 'Jaguar'
	select @RoverBrandID = ID from BrandMaster where BrandName = 'Land rover'
	select @RenaultBrandID = ID from BrandMaster where BrandName = 'Renault'
	
	

	select @overAllSalesAmount = 
		(AudiSales * dbo.GetBrandWiseClassA_CarPrice(@AudiBrandID)) +
		(JaguarSales* dbo.GetBrandWiseClassA_CarPrice(@JaguarBrandID)) +
		(RoverSales* dbo.GetBrandWiseClassA_CarPrice(@RoverBrandID)) +
		(RenaultSales* dbo.GetBrandWiseClassA_CarPrice(@RenaultBrandID))
	from MonthlyReport 
	where SalesPersonID = @SalesPersonID and ClassID = 1
	
	if(@LastYearSale > 500000)
	begin
		set @AdditionalCommission = (@overAllSalesAmount * 2)/100
	end
	return @AdditionalCommission
end
GO
/****** Object:  UserDefinedFunction [dbo].[GetBrandWiseClassA_CarPrice]    Script Date: 09-02-2024 7.06.50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[GetBrandWiseClassA_CarPrice](@BrandID nvarchar(50))
returns decimal(18,2)
as
begin
	declare @Price decimal(18,2) = 0
	
	select 
		@Price = sum(Price)
	from Cars where ClassID = 1
	group by BrandID
	having BrandID = @BrandID


	

	return @Price
	
end
GO
/****** Object:  UserDefinedFunction [dbo].[GetCarModelPriceByCarBrand]    Script Date: 09-02-2024 7.06.50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[GetCarModelPriceByCarBrand](@BrandName as varchar(50))
returns decimal(18,2)
as
begin
	declare @Price decimal(18,2) = 0
	
	select @Price = sum(Price) from Cars
		join BrandMaster BM on BM.ID = Cars.BrandID
	where BM.BrandName = @BrandName

	
	return @Price
end
GO
/****** Object:  UserDefinedFunction [dbo].[GetCarModelPriceByCarBrandAndClass]    Script Date: 09-02-2024 7.06.50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create function [dbo].[GetCarModelPriceByCarBrandAndClass](@BrandName as varchar(50), @Class as varchar(50))
returns decimal(18,2)
as
begin
	declare @Price decimal(18,2) = 0
	
	select @Price = sum(Price) from Cars
		join BrandMaster BM on BM.ID = Cars.BrandID
		join ClassMaster CM on CM.ID = Cars.ClassID
	where BM.BrandName = @BrandName and CM.Class = @Class

	
	return @Price
end
GO
/****** Object:  UserDefinedFunction [dbo].[GetClassWiseCommissionByCarBrandAndClass]    Script Date: 09-02-2024 7.06.50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[GetClassWiseCommissionByCarBrandAndClass](@BrandName as varchar(50), @Class as varchar(50))
returns decimal(18,2)
as
begin
	declare @ClassWiseCommission decimal(18,2) = 0
	declare @CarModelPrice decimal(18,2) = 0
	set @CarModelPrice = dbo.GetCarModelPriceByCarBrandAndClass(@BrandName,@Class)

	
	declare @Column nvarchar(50) = '';
	if(lower(@Class) = lower('A-Class'))
	begin
		
		select
			@ClassWiseCommission =
				(@CarModelPrice*ClassACommission)/100 
		from CommissionMaster
			join BrandMaster BM on BM.ID = CommissionMaster.BrandID
		where BM.BrandName = @BrandName 
	end
	else if(lower(@Class) = lower('B-Class'))
	begin
		

		select
			@ClassWiseCommission =
				(@CarModelPrice*ClassBCommission)/100 
		from CommissionMaster
			join BrandMaster BM on BM.ID = CommissionMaster.BrandID
		where BM.BrandName = @BrandName 


	end
	else if(lower(@Class) = lower('C-Class'))
	begin
		


		select
			@ClassWiseCommission =
				(@CarModelPrice*ClassCCommission)/100 
		from CommissionMaster
			join BrandMaster BM on BM.ID = CommissionMaster.BrandID
		where BM.BrandName = @BrandName 
	end
	
	
	

	


	return @ClassWiseCommission
end
GO
/****** Object:  UserDefinedFunction [dbo].[GetFixedCommissionByCarBrand]    Script Date: 09-02-2024 7.06.50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[GetFixedCommissionByCarBrand](@BrandName as varchar(50))
returns decimal(18,2)
as
begin
	declare @FixedCommission decimal(18,2) = 0
	declare @CarModelPrice decimal(18,2) = 0
	set @CarModelPrice = dbo.GetCarModelPriceByCarBrand(@BrandName)

	select
		@FixedCommission =
		case when (@CarModelPrice>CommissionMaster.FixedCommisionPriceLimit) 
			then CommissionMaster.FixedCommision else 0 end 
	from CommissionMaster
		join BrandMaster BM on BM.ID = CommissionMaster.BrandID
	where BM.BrandName = @BrandName


	


	return @FixedCommission
end
GO
/****** Object:  UserDefinedFunction [dbo].[GetNumberOfSalesByCarBrandAndClass]    Script Date: 09-02-2024 7.06.50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[GetNumberOfSalesByCarBrandAndClass](@SalesPersonID int,@BrandName varchar(50),@ClassName varchar(50))
returns decimal(18,2)
as
begin
	
	


	declare @NumberOfSales decimal(18,2) = 0
	declare @ClassID int = 0

	set @ClassID = (select ID from ClassMaster where lower(Class) = lower(@ClassName))

	
	
	if(lower(@BrandName) = lower('Audi'))
	begin
		select @NumberOfSales = AudiSales from MonthlyReport where SalesPersonID = @SalesPersonID and ClassID = @ClassID
	end
	else if(lower(@BrandName) = lower('Jaguar'))
	begin
		select @NumberOfSales = JaguarSales from MonthlyReport where SalesPersonID = @SalesPersonID and ClassID = @ClassID
	end
	else if(lower(@BrandName) = lower('Land rover'))
	begin
		select @NumberOfSales = RoverSales from MonthlyReport where SalesPersonID = @SalesPersonID and ClassID = @ClassID
	end
	else if(lower(@BrandName) = lower('Renault'))
	begin
		select @NumberOfSales = RenaultSales from MonthlyReport where SalesPersonID = @SalesPersonID and ClassID = @ClassID
	end

	return @NumberOfSales
end
GO
/****** Object:  Table [dbo].[BrandMaster]    Script Date: 09-02-2024 7.06.50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BrandMaster](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[BrandName] [nvarchar](25) NULL,
 CONSTRAINT [PK_BrandMaster] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[CarImages]    Script Date: 09-02-2024 7.06.51 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CarImages](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[CarID] [int] NULL,
	[ImageName] [nvarchar](50) NULL,
 CONSTRAINT [PK_CarImages] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Cars]    Script Date: 09-02-2024 7.06.51 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Cars](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[BrandID] [int] NOT NULL,
	[ClassID] [int] NOT NULL,
	[ModelName] [nvarchar](50) NOT NULL,
	[ModelCode] [nvarchar](10) NOT NULL,
	[Description] [nvarchar](max) NOT NULL,
	[Features] [nvarchar](max) NOT NULL,
	[Price] [decimal](18, 2) NOT NULL,
	[DateOfManufacturing] [date] NOT NULL,
	[IsActive] [bit] NULL,
	[OrderBy] [int] NULL,
 CONSTRAINT [PK_Cars] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[ClassMaster]    Script Date: 09-02-2024 7.06.51 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ClassMaster](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Class] [nvarchar](25) NULL,
 CONSTRAINT [PK_ClassMaster] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[CommissionMaster]    Script Date: 09-02-2024 7.06.51 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CommissionMaster](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[BrandID] [int] NULL,
	[FixedCommision] [numeric](18, 2) NULL,
	[ClassACommission] [numeric](18, 2) NULL,
	[ClassBCommission] [numeric](18, 2) NULL,
	[ClassCCommission] [numeric](18, 2) NULL,
	[FixedCommisionPriceLimit] [numeric](18, 2) NULL,
 CONSTRAINT [PK_CommissionMaster] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[LastYearSales]    Script Date: 09-02-2024 7.06.51 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LastYearSales](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[SalesPersonID] [int] NULL,
	[LastYearTotalSale] [decimal](18, 2) NULL,
 CONSTRAINT [PK_LastYearSales] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[MonthlyReport]    Script Date: 09-02-2024 7.06.51 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MonthlyReport](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[SalesPersonID] [int] NULL,
	[ClassID] [int] NULL,
	[AudiSales] [int] NULL,
	[JaguarSales] [int] NULL,
	[RoverSales] [int] NULL,
	[RenaultSales] [int] NULL,
 CONSTRAINT [PK_MonthlyReport] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[SalesPersons]    Script Date: 09-02-2024 7.06.51 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SalesPersons](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[SalesPersonName] [nvarchar](50) NULL,
 CONSTRAINT [PK_SalesPersons] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
SET IDENTITY_INSERT [dbo].[BrandMaster] ON 
GO
INSERT [dbo].[BrandMaster] ([ID], [BrandName]) VALUES (1, N'Audi')
GO
INSERT [dbo].[BrandMaster] ([ID], [BrandName]) VALUES (2, N'Jaguar')
GO
INSERT [dbo].[BrandMaster] ([ID], [BrandName]) VALUES (3, N'Land rover')
GO
INSERT [dbo].[BrandMaster] ([ID], [BrandName]) VALUES (1002, N'Renault')
GO
SET IDENTITY_INSERT [dbo].[BrandMaster] OFF
GO
SET IDENTITY_INSERT [dbo].[CarImages] ON 
GO
INSERT [dbo].[CarImages] ([ID], [CarID], [ImageName]) VALUES (14, 14, N'14_20240209-051940.jpg')
GO
INSERT [dbo].[CarImages] ([ID], [CarID], [ImageName]) VALUES (15, 19, N'19_20240209-051959.jpeg')
GO
INSERT [dbo].[CarImages] ([ID], [CarID], [ImageName]) VALUES (16, 1009, N'1009_20240209-052022.jpg')
GO
SET IDENTITY_INSERT [dbo].[CarImages] OFF
GO
SET IDENTITY_INSERT [dbo].[Cars] ON 
GO
INSERT [dbo].[Cars] ([ID], [BrandID], [ClassID], [ModelName], [ModelCode], [Description], [Features], [Price], [DateOfManufacturing], [IsActive], [OrderBy]) VALUES (14, 1, 1, N'Audi-A-Class', N'AAC', N'asdf555555555558', N'af', CAST(800000.00 AS Decimal(18, 2)), CAST(N'2005-05-25' AS Date), 1, 1)
GO
INSERT [dbo].[Cars] ([ID], [BrandID], [ClassID], [ModelName], [ModelCode], [Description], [Features], [Price], [DateOfManufacturing], [IsActive], [OrderBy]) VALUES (19, 1, 2, N'Audi-B-Class', N'ABC', N'zvczv852', N'zcvz258', CAST(1200000.00 AS Decimal(18, 2)), CAST(N'2021-12-12' AS Date), 1, 1)
GO
INSERT [dbo].[Cars] ([ID], [BrandID], [ClassID], [ModelName], [ModelCode], [Description], [Features], [Price], [DateOfManufacturing], [IsActive], [OrderBy]) VALUES (1009, 1, 3, N'Audi-C-Class', N'ACC', N'dasfdaf', N'dfsdfs', CAST(4500000.00 AS Decimal(18, 2)), CAST(N'2020-12-12' AS Date), 1, 1)
GO
INSERT [dbo].[Cars] ([ID], [BrandID], [ClassID], [ModelName], [ModelCode], [Description], [Features], [Price], [DateOfManufacturing], [IsActive], [OrderBy]) VALUES (1010, 2, 1, N'Jaguar-A-Class', N'JAC', N'asdfasfasdf', N'adfafd', CAST(2500000.00 AS Decimal(18, 2)), CAST(N'2006-11-12' AS Date), 1, 1)
GO
INSERT [dbo].[Cars] ([ID], [BrandID], [ClassID], [ModelName], [ModelCode], [Description], [Features], [Price], [DateOfManufacturing], [IsActive], [OrderBy]) VALUES (1011, 2, 2, N'Jaguar-B-Class', N'JBC', N'sdfadfas', N'asfdsa', CAST(300000.00 AS Decimal(18, 2)), CAST(N'2005-12-12' AS Date), 1, 1)
GO
INSERT [dbo].[Cars] ([ID], [BrandID], [ClassID], [ModelName], [ModelCode], [Description], [Features], [Price], [DateOfManufacturing], [IsActive], [OrderBy]) VALUES (1012, 2, 3, N'Jaguar-C-Class', N'JCC', N'sfasfas', N'asfdasf', CAST(258000.00 AS Decimal(18, 2)), CAST(N'2005-01-12' AS Date), 1, 1)
GO
INSERT [dbo].[Cars] ([ID], [BrandID], [ClassID], [ModelName], [ModelCode], [Description], [Features], [Price], [DateOfManufacturing], [IsActive], [OrderBy]) VALUES (1013, 3, 1, N'LandRover-A-Class', N'LAC', N'asfasdf', N'afsfasf', CAST(500000.00 AS Decimal(18, 2)), CAST(N'2008-12-12' AS Date), 1, 1)
GO
INSERT [dbo].[Cars] ([ID], [BrandID], [ClassID], [ModelName], [ModelCode], [Description], [Features], [Price], [DateOfManufacturing], [IsActive], [OrderBy]) VALUES (1014, 3, 2, N'LandRover-B-Class', N'LBC', N'asdfadfasf', N'asfaf', CAST(58854.00 AS Decimal(18, 2)), CAST(N'2005-12-12' AS Date), 1, 1)
GO
INSERT [dbo].[Cars] ([ID], [BrandID], [ClassID], [ModelName], [ModelCode], [Description], [Features], [Price], [DateOfManufacturing], [IsActive], [OrderBy]) VALUES (1015, 3, 3, N'LandRover-C-Class', N'LCC', N'asdfaf', N'asdfasfd', CAST(25000.00 AS Decimal(18, 2)), CAST(N'2001-12-12' AS Date), 1, 1)
GO
INSERT [dbo].[Cars] ([ID], [BrandID], [ClassID], [ModelName], [ModelCode], [Description], [Features], [Price], [DateOfManufacturing], [IsActive], [OrderBy]) VALUES (1016, 1002, 1, N'Renault-A-Class', N'RAC', N'asfasfdasf', N'asdfasdf', CAST(2500.00 AS Decimal(18, 2)), CAST(N'2008-12-12' AS Date), 1, 1)
GO
INSERT [dbo].[Cars] ([ID], [BrandID], [ClassID], [ModelName], [ModelCode], [Description], [Features], [Price], [DateOfManufacturing], [IsActive], [OrderBy]) VALUES (1017, 1002, 2, N'Renault-B-Class', N'RBC', N'asdfasf', N'asfasf', CAST(685005.00 AS Decimal(18, 2)), CAST(N'2004-12-15' AS Date), 1, 1)
GO
INSERT [dbo].[Cars] ([ID], [BrandID], [ClassID], [ModelName], [ModelCode], [Description], [Features], [Price], [DateOfManufacturing], [IsActive], [OrderBy]) VALUES (1018, 1002, 3, N'Renault-C-Class', N'RCC', N'asfdafasf', N'asdfasfdasf', CAST(250000.00 AS Decimal(18, 2)), CAST(N'2005-12-12' AS Date), 1, 1)
GO
SET IDENTITY_INSERT [dbo].[Cars] OFF
GO
SET IDENTITY_INSERT [dbo].[ClassMaster] ON 
GO
INSERT [dbo].[ClassMaster] ([ID], [Class]) VALUES (1, N'A-Class')
GO
INSERT [dbo].[ClassMaster] ([ID], [Class]) VALUES (2, N'B-Class')
GO
INSERT [dbo].[ClassMaster] ([ID], [Class]) VALUES (3, N'C-Class')
GO
SET IDENTITY_INSERT [dbo].[ClassMaster] OFF
GO
SET IDENTITY_INSERT [dbo].[CommissionMaster] ON 
GO
INSERT [dbo].[CommissionMaster] ([ID], [BrandID], [FixedCommision], [ClassACommission], [ClassBCommission], [ClassCCommission], [FixedCommisionPriceLimit]) VALUES (1, 1, CAST(800.00 AS Numeric(18, 2)), CAST(8.00 AS Numeric(18, 2)), CAST(6.00 AS Numeric(18, 2)), CAST(4.00 AS Numeric(18, 2)), CAST(25000.00 AS Numeric(18, 2)))
GO
INSERT [dbo].[CommissionMaster] ([ID], [BrandID], [FixedCommision], [ClassACommission], [ClassBCommission], [ClassCCommission], [FixedCommisionPriceLimit]) VALUES (2, 2, CAST(750.00 AS Numeric(18, 2)), CAST(6.00 AS Numeric(18, 2)), CAST(5.00 AS Numeric(18, 2)), CAST(3.00 AS Numeric(18, 2)), CAST(35000.00 AS Numeric(18, 2)))
GO
INSERT [dbo].[CommissionMaster] ([ID], [BrandID], [FixedCommision], [ClassACommission], [ClassBCommission], [ClassCCommission], [FixedCommisionPriceLimit]) VALUES (3, 3, CAST(850.00 AS Numeric(18, 2)), CAST(7.00 AS Numeric(18, 2)), CAST(5.00 AS Numeric(18, 2)), CAST(4.00 AS Numeric(18, 2)), CAST(30000.00 AS Numeric(18, 2)))
GO
INSERT [dbo].[CommissionMaster] ([ID], [BrandID], [FixedCommision], [ClassACommission], [ClassBCommission], [ClassCCommission], [FixedCommisionPriceLimit]) VALUES (4, 1002, CAST(400.00 AS Numeric(18, 2)), CAST(5.00 AS Numeric(18, 2)), CAST(3.00 AS Numeric(18, 2)), CAST(2.00 AS Numeric(18, 2)), CAST(20000.00 AS Numeric(18, 2)))
GO
SET IDENTITY_INSERT [dbo].[CommissionMaster] OFF
GO
SET IDENTITY_INSERT [dbo].[LastYearSales] ON 
GO
INSERT [dbo].[LastYearSales] ([ID], [SalesPersonID], [LastYearTotalSale]) VALUES (1, 1, CAST(490000.00 AS Decimal(18, 2)))
GO
INSERT [dbo].[LastYearSales] ([ID], [SalesPersonID], [LastYearTotalSale]) VALUES (2, 2, CAST(1000000.00 AS Decimal(18, 2)))
GO
INSERT [dbo].[LastYearSales] ([ID], [SalesPersonID], [LastYearTotalSale]) VALUES (3, 3, CAST(650000.00 AS Decimal(18, 2)))
GO
SET IDENTITY_INSERT [dbo].[LastYearSales] OFF
GO
SET IDENTITY_INSERT [dbo].[MonthlyReport] ON 
GO
INSERT [dbo].[MonthlyReport] ([ID], [SalesPersonID], [ClassID], [AudiSales], [JaguarSales], [RoverSales], [RenaultSales]) VALUES (1, 1, 1, 1, 3, 0, 6)
GO
INSERT [dbo].[MonthlyReport] ([ID], [SalesPersonID], [ClassID], [AudiSales], [JaguarSales], [RoverSales], [RenaultSales]) VALUES (2, 1, 2, 2, 4, 2, 2)
GO
INSERT [dbo].[MonthlyReport] ([ID], [SalesPersonID], [ClassID], [AudiSales], [JaguarSales], [RoverSales], [RenaultSales]) VALUES (3, 1, 3, 3, 6, 1, 1)
GO
INSERT [dbo].[MonthlyReport] ([ID], [SalesPersonID], [ClassID], [AudiSales], [JaguarSales], [RoverSales], [RenaultSales]) VALUES (4, 2, 1, 0, 5, 5, 3)
GO
INSERT [dbo].[MonthlyReport] ([ID], [SalesPersonID], [ClassID], [AudiSales], [JaguarSales], [RoverSales], [RenaultSales]) VALUES (5, 2, 2, 0, 4, 2, 2)
GO
INSERT [dbo].[MonthlyReport] ([ID], [SalesPersonID], [ClassID], [AudiSales], [JaguarSales], [RoverSales], [RenaultSales]) VALUES (6, 2, 3, 0, 2, 1, 1)
GO
INSERT [dbo].[MonthlyReport] ([ID], [SalesPersonID], [ClassID], [AudiSales], [JaguarSales], [RoverSales], [RenaultSales]) VALUES (7, 3, 1, 4, 2, 1, 6)
GO
INSERT [dbo].[MonthlyReport] ([ID], [SalesPersonID], [ClassID], [AudiSales], [JaguarSales], [RoverSales], [RenaultSales]) VALUES (8, 3, 2, 2, 7, 2, 3)
GO
INSERT [dbo].[MonthlyReport] ([ID], [SalesPersonID], [ClassID], [AudiSales], [JaguarSales], [RoverSales], [RenaultSales]) VALUES (9, 3, 3, 0, 1, 3, 1)
GO
SET IDENTITY_INSERT [dbo].[MonthlyReport] OFF
GO
SET IDENTITY_INSERT [dbo].[SalesPersons] ON 
GO
INSERT [dbo].[SalesPersons] ([ID], [SalesPersonName]) VALUES (1, N'John Smith')
GO
INSERT [dbo].[SalesPersons] ([ID], [SalesPersonName]) VALUES (2, N'Richard Porter')
GO
INSERT [dbo].[SalesPersons] ([ID], [SalesPersonName]) VALUES (3, N'Tony Grid')
GO
SET IDENTITY_INSERT [dbo].[SalesPersons] OFF
GO
ALTER TABLE [dbo].[CarImages]  WITH CHECK ADD  CONSTRAINT [FK_CarImages_Cars] FOREIGN KEY([CarID])
REFERENCES [dbo].[Cars] ([ID])
GO
ALTER TABLE [dbo].[CarImages] CHECK CONSTRAINT [FK_CarImages_Cars]
GO
ALTER TABLE [dbo].[Cars]  WITH CHECK ADD  CONSTRAINT [FK_Cars_BrandMaster] FOREIGN KEY([BrandID])
REFERENCES [dbo].[BrandMaster] ([ID])
GO
ALTER TABLE [dbo].[Cars] CHECK CONSTRAINT [FK_Cars_BrandMaster]
GO
ALTER TABLE [dbo].[Cars]  WITH CHECK ADD  CONSTRAINT [FK_Cars_ClassMaster] FOREIGN KEY([ClassID])
REFERENCES [dbo].[ClassMaster] ([ID])
GO
ALTER TABLE [dbo].[Cars] CHECK CONSTRAINT [FK_Cars_ClassMaster]
GO
/****** Object:  StoredProcedure [dbo].[usp_AddCarImage]    Script Date: 09-02-2024 7.06.51 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[usp_AddCarImage]
@CarID int,
@ImageName nvarchar(50)
as
begin
	insert into CarImages values(@CarID,@ImageName)
end
GO
/****** Object:  StoredProcedure [dbo].[usp_DeleteCarByID]    Script Date: 09-02-2024 7.06.51 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[usp_DeleteCarByID]
@ID int
as
begin
	delete from Cars where ID=@ID
end
GO
/****** Object:  StoredProcedure [dbo].[usp_DeleteCarImageByID]    Script Date: 09-02-2024 7.06.51 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[usp_DeleteCarImageByID]
@ID int
as
begin
	delete from CarImages where ID=@ID
end
GO
/****** Object:  StoredProcedure [dbo].[usp_Generate_Salesman_Commission_Report]    Script Date: 09-02-2024 7.06.51 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc [dbo].[usp_Generate_Salesman_Commission_Report]
as
begin
	
	select 
		max(SP.SalesPersonName) SalesPersonName,
		MonthlyReport.SalesPersonID SalesPersonID,
		--Sum(AudiSales) Audi,
		dbo.GetFixedCommissionByCarBrand('Audi') * Sum(AudiSales) 'Audi_FixedCommission',
		dbo.GetClassWiseCommissionByCarBrandAndClass('Audi','A-Class') * dbo.GetNumberOfSalesByCarBrandAndClass(SalesPersonID,'Audi','A-Class') 'Audi_ClassA_Commission',
		dbo.GetClassWiseCommissionByCarBrandAndClass('Audi','B-Class') * dbo.GetNumberOfSalesByCarBrandAndClass(SalesPersonID,'Audi','B-Class') 'Audi_ClassB_Commission',
		dbo.GetClassWiseCommissionByCarBrandAndClass('Audi','C-Class') * dbo.GetNumberOfSalesByCarBrandAndClass(SalesPersonID,'Audi','C-Class') 'Audi_ClassC_Commission',
		
		
		--Sum(JaguarSales) Jaguar,
		dbo.GetFixedCommissionByCarBrand('Jaguar') * Sum(JaguarSales) 'Jaguar_FixedCommission',
		dbo.GetClassWiseCommissionByCarBrandAndClass('Jaguar','A-Class') * dbo.GetNumberOfSalesByCarBrandAndClass(SalesPersonID,'Jaguar','A-Class') 'Jaguar_ClassA_Commission',
		dbo.GetClassWiseCommissionByCarBrandAndClass('Jaguar','B-Class') * dbo.GetNumberOfSalesByCarBrandAndClass(SalesPersonID,'Jaguar','B-Class') 'Jaguar_ClassB_Commission',
		dbo.GetClassWiseCommissionByCarBrandAndClass('Jaguar','C-Class') * dbo.GetNumberOfSalesByCarBrandAndClass(SalesPersonID,'Jaguar','C-Class') 'Jaguar_ClassC_Commission',
		
		
		--SUM(RoverSales) Rover,
		dbo.GetFixedCommissionByCarBrand('Land rover') * Sum(RoverSales) 'Rover_FixedCommission',
		dbo.GetClassWiseCommissionByCarBrandAndClass('Land rover','A-Class') * dbo.GetNumberOfSalesByCarBrandAndClass(SalesPersonID,'Land rover','A-Class') 'Rover_ClassA_Commission',
		dbo.GetClassWiseCommissionByCarBrandAndClass('Land rover','B-Class') * dbo.GetNumberOfSalesByCarBrandAndClass(SalesPersonID,'Land rover','B-Class') 'Rover_ClassB_Commission',
		dbo.GetClassWiseCommissionByCarBrandAndClass('Land rover','C-Class') * dbo.GetNumberOfSalesByCarBrandAndClass(SalesPersonID,'Land rover','C-Class') 'Rover_ClassC_Commission',
		
		Sum(RenaultSales) Renault,
		dbo.GetFixedCommissionByCarBrand('Renault') * Sum(RenaultSales) 'Renault_FixedCommission',
		dbo.GetClassWiseCommissionByCarBrandAndClass('Renault','A-Class') * dbo.GetNumberOfSalesByCarBrandAndClass(SalesPersonID,'Renault','A-Class') 'Renault_ClassA_Commission',
		dbo.GetClassWiseCommissionByCarBrandAndClass('Renault','B-Class') * dbo.GetNumberOfSalesByCarBrandAndClass(SalesPersonID,'Renault','B-Class') 'Renault_ClassB_Commission',
		dbo.GetClassWiseCommissionByCarBrandAndClass('Renault','C-Class') * dbo.GetNumberOfSalesByCarBrandAndClass(SalesPersonID,'Renault','C-Class') 'Renault_ClassC_Commission'

		,dbo.GetAdditionalCommission(SalesPersonID) 'Additional_Commission'


	from MonthlyReport
		join SalesPersons SP on SP.ID = MonthlyReport.SalesPersonID
	group by SalesPersonID
	
	
	
	
end

GO
/****** Object:  StoredProcedure [dbo].[usp_GetAllBrands]    Script Date: 09-02-2024 7.06.51 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[usp_GetAllBrands]
as
begin
	select ID, BrandName from BrandMaster
end
GO
/****** Object:  StoredProcedure [dbo].[usp_GetAllCarImages]    Script Date: 09-02-2024 7.06.51 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[usp_GetAllCarImages]
@CarID int
as
begin
	select ID,CarID,ImageName from CarImages where CarID = @CarID
end
GO
/****** Object:  StoredProcedure [dbo].[usp_GetAllCars]    Script Date: 09-02-2024 7.06.51 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_GetAllCars]
as
begin
	select 
		Cars.ID ID, 
		BrandID,
		BM.BrandName,
		ClassID, 
		CM.Class,
		ModelName, 
		ModelCode, 
		Description, 
		Features, 
		Price, 
		DateOfManufacturing, 
		IsActive, 
		OrderBy
	from Cars
		join BrandMaster BM on BM.ID= Cars.BrandID
		join ClassMaster CM on CM.ID = Cars.ClassID
	order by ID
end
GO
/****** Object:  StoredProcedure [dbo].[usp_GetAllClass]    Script Date: 09-02-2024 7.06.51 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[usp_GetAllClass]
as
begin
	select ID,Class from ClassMaster
end
GO
/****** Object:  StoredProcedure [dbo].[usp_GetCarDetailsByID]    Script Date: 09-02-2024 7.06.51 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[usp_GetCarDetailsByID]
@ID int
as
begin
	select 
		Cars.ID ID, 
		BrandID,
		BM.BrandName,
		ClassID, 
		CM.Class,
		ModelName, 
		ModelCode, 
		Description, 
		Features, 
		Price, 
		DateOfManufacturing, 
		IsActive, 
		OrderBy
	from Cars
		join BrandMaster BM on BM.ID= Cars.BrandID
		join ClassMaster CM on CM.ID = Cars.ClassID
	where Cars.ID = @ID
end
GO
/****** Object:  StoredProcedure [dbo].[usp_InsertUpdate_Car]    Script Date: 09-02-2024 7.06.51 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[usp_InsertUpdate_Car]
@ID int, 
@BrandID int, 
@ClassID int, 
@ModelName nvarchar(50), 
@ModelCode nvarchar(10), 
@Description nvarchar(max), 
@Features nvarchar(max), 
@Price decimal(18,2), 
@DateOfManufacturing date, 
@IsActive bit, 
@OrderBy int
as
begin
	if (@ID > 0)
	begin
		--Update
		UPDATE [dbo].[Cars]
   SET [BrandID] = @BrandID
      ,[ClassID] = @ClassID
      ,[ModelName] = @ModelName
      ,[ModelCode] = @ModelCode
      ,[Description] = @Description
      ,[Features] = @Features
      ,[Price] = @Price
      ,[DateOfManufacturing] = @DateOfManufacturing
      ,[IsActive] = @IsActive
      ,[OrderBy] = @OrderBy
 WHERE ID = @ID
	end
	else
	begin
		--Insert
		INSERT INTO [dbo].[Cars]
           ([BrandID]
           ,[ClassID]
           ,[ModelName]
           ,[ModelCode]
           ,[Description]
           ,[Features]
           ,[Price]
           ,[DateOfManufacturing]
           ,[IsActive]
           ,[OrderBy])
     VALUES
           (@BrandID, @ClassID, @ModelName, @ModelCode, @Description, @Features, @Price, @DateOfManufacturing, @IsActive, @OrderBy)
	end
end
GO
