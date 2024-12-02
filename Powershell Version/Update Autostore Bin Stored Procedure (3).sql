USE [Exactadb]
GO

/****** Object:  StoredProcedure [dbo].[spAddAutomationBinLocation]    Script Date: 7/14/2021 3:56:53 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




-- =============================================
-- Author:		Kyle Creekmore/Craig Lee
-- Create date: 5/16/2018
-- Description:	Creates bins in exacta based on exported csv file from autostore
-- Version:		3.0
--		3/7/19 Updates:
--		1. S/P will now first check if the bin already exists and exit out if so. Should improve preformance of this process
--		2. S/P will now check if the content code is = 10. If it is not, it will not add the bin (No change here, just a better check)
--		3. S/P will now only not add the bin to Exacta DB if it is in OUTSIDE Mode. Before, it would only add bins that were in GRID mode. Now it will add anything thats not in OUTSIDE mode.
--		4. Improved Log statements
-- =============================================
ALTER PROCEDURE [dbo].[spAddAutomationBinLocation]
	-- Add the parameters for the stored procedure here
	@automationContainerName varchar(30),
	@cellPatternName varchar(30),
	@warehouse varchar(4),
	@zone varchar(4),
	@workAreaName varchar(4)

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	
	--Checks if the Container already exists
	if exists (select 1 from automation_cntnr_header where automation_cntnr_name=@automationContainerName)
	begin
		print 'ERROR: Automation container ' + @automationContainerName + ' already exists and wont be added'
		return
	end


	--sets cntnrpatternid and checks to make sure pattern name is getting translated properly	
	declare @cntnrPatternId as uid 
    select @cntnrPatternId = cntnr_pattern_id from cntnr_pattern where cntnr_pattern_name=@cellPatternName
	if @cntnrPatternId is null
	begin
		print 'ERROR: Automation container ' +@automationContainerName + ' with pattern '+ @cellPatternName + ' is invalid, check stored procedure case statement for pattern translation'
		return
	end
	
    if exists (select 1 from automation_cntnr_header where automation_cntnr_name=@automationContainerName)
	begin
		print 'ERROR: Automation container ' + @automationContainerName + ' already exists and wont be added'
		return
	end

    if not exists (select 1 from warehouse where warehouse_name=@warehouse)
	begin
		print 'ERROR: Warehouse ' + @warehouse + ' does not exist for container ' + @automationContainerName
		return
	end
	
	declare @zoneId as uid
    select @zoneId = zone_id from zone_header where zone_num=@zone
		
	if @zoneId is null
	begin
		print 'ERROR: Zone ' + @zone + ' does not exist for container ' +@automationContainerName 
		return
	end

	declare @workAreaId as uid
	select @workAreaId = work_area_id from work_area_header where work_area_name=@workAreaName

	if @workAreaId is null
	begin	
		print 'ERROR: Work area ' + @workAreaName + ' does not exist for container ' + @automationContainerName
		return
	end

	declare @maxWeight as numeric(19,6)
	select @maxWeight = sum(weight) from cntnr_pattern_cell where cntnr_pattern_id=@cntnrPatternId

	print 'Adding automation container ' + @automationContainerName

	-- Creation Automation Container
	declare @automationCntnrId as uid = newid()
	insert into automation_cntnr_header (automation_cntnr_id, automation_cntnr_name, cntnr_pattern_id, max_weight, batch_num)
	values (@automationCntnrId, @automationContainerName, @cntnrPatternId, @maxWeight, null)
	
	declare @sixCharacterId as char(7)
	set @sixCharacterId = right('0000000' + @automationContainerName, 7)

	-- Create Locations
	INSERT INTO [dbo].[loc_header]
           ([loc_id],[whse_num],[zone_num],[row_num],[bay_num],[shelf_num],[cell_num],[loc_barcode],[loc_seq],[alt_loc_seq],[loc_type]
           ,[loc_status],[equipment],[velocity],[loc_depth],[loc_width],[loc_height],[loc_weight],[loc_fixed],[check_digit],[loc_alias]
           ,[lane_id],[work_area_id],[zone_id],[family_group],[max_inventory_containers],[is_consolidation_full],[is_conveyable],[automation_cntnr_id],[cntnr_pattern_cell_id],[last_cycle_count])
	select newid(), @warehouse, @zone, substring(@sixCharacterId, 2,2), substring(@sixCharacterId, 4, 2), right(@sixCharacterId, 2), cpc.cell_name, concat(@automationContainerName,'-',cpc.cell_name), @automationContainerName, 1, 1,
			0, 0, 0, cpc.depth, cpc.width, cpc.height, cpc.weight, null, null, concat(@automationContainerName,'-',cpc.cell_name),
			null, @workAreaId, @zoneId, 0, 1, 0, 0, @automationCntnrId, cpc.cntnr_pattern_cell_id, null
	from automation_cntnr_header a
	inner join cntnr_pattern_cell cpc on a.cntnr_pattern_id=cpc.cntnr_pattern_id
	where a.automation_cntnr_id=@automationCntnrId


	-- Create Inventory Containers at locations
	INSERT INTO [dbo].[cntnr_header]
           ([cntnr_id],[cntnr_type],[cntnr_name],[parent_cntnr_id],[loc_id],[lane_id],[cntnr_wgt_min],[cntnr_wgt_max],[cntnr_wgt],[cntnr_wgt_tolerance]
			,[cntnr_wgt_estimated],[qc_required],[qc_reason_type],[pack_qc_required],[is_movable_unit],[batch_num],[document_id],[cntnr_width],[cntnr_depth],[cntnr_height]
			,[cube_category],[has_been_forecasted],[user_id],[is_vas_complete],[hazard_level],[wgt_check_result],[calculated_q_factor],[dry_ice_wgt],[cntnr_alias])
	select newid(), 0, concat(@automationContainerName,'-',lh.cell_num), null, lh.loc_id, null,0,0,lh.loc_weight, 0,
			0, 0, null, 0, 0, null, null, lh.loc_width, lh.loc_depth, lh.loc_height,
			null, 0, null, 0, null, null, null, null, null
	from loc_header lh
	where lh.automation_cntnr_id=@automationCntnrId

END


GO


