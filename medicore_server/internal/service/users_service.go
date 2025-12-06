package service

import (
	"context"
	"database/sql"
	"time"

	"medicore/internal/models"
	"medicore/internal/repository"
	pb "medicore/proto"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

// UsersService implements the gRPC UsersService
type UsersService struct {
	pb.UnimplementedUsersServiceServer
	usersRepo     *repository.UsersRepository
	templatesRepo *repository.TemplatesRepository
}

// NewUsersService creates a new users service
func NewUsersService(db *sql.DB) *UsersService {
	return &UsersService{
		usersRepo:     repository.NewUsersRepository(db),
		templatesRepo: repository.NewTemplatesRepository(db),
	}
}

// SyncUsers syncs users from client to server
func (s *UsersService) SyncUsers(ctx context.Context, req *pb.SyncUsersRequest) (*pb.SyncUsersResponse, error) {
	// Process local changes from client
	for _, userPb := range req.LocalChanges {
		user := protoToUser(userPb)

		// Check if user exists
		existing, err := s.usersRepo.GetByID(user.ID)
		if err != nil {
			return nil, status.Errorf(codes.Internal, "failed to check user: %v", err)
		}

		if existing == nil {
			// Create new user
			if err := s.usersRepo.Create(user); err != nil {
				return nil, status.Errorf(codes.Internal, "failed to create user: %v", err)
			}
		} else {
			// Update if client version is newer
			if user.SyncVersion > existing.SyncVersion {
				if err := s.usersRepo.Update(user); err != nil {
					return nil, status.Errorf(codes.Internal, "failed to update user: %v", err)
				}
			}
		}
	}

	// Get server updates since last sync
	lastSync := time.Unix(req.LastSyncTimestamp, 0)
	updatedUsers, err := s.usersRepo.GetUpdatedSince(lastSync)
	if err != nil {
		return nil, status.Errorf(codes.Internal, "failed to get updated users: %v", err)
	}

	// Convert to protobuf
	var usersPb []*pb.User
	var deletedIds []string

	for _, user := range updatedUsers {
		if user.DeletedAt != nil {
			deletedIds = append(deletedIds, user.ID)
		} else {
			usersPb = append(usersPb, userToProto(user))
		}
	}

	return &pb.SyncUsersResponse{
		ServerUpdates:   usersPb,
		DeletedIds:      deletedIds,
		ServerTimestamp: time.Now().Unix(),
	}, nil
}

// SyncTemplates syncs templates from client to server
func (s *UsersService) SyncTemplates(ctx context.Context, req *pb.SyncTemplatesRequest) (*pb.SyncTemplatesResponse, error) {
	// Process local changes from client
	for _, templatePb := range req.LocalChanges {
		template := protoToTemplate(templatePb)

		// Check if template exists
		existing, err := s.templatesRepo.GetByID(template.ID)
		if err != nil {
			return nil, status.Errorf(codes.Internal, "failed to check template: %v", err)
		}

		if existing == nil {
			// Create new template
			if err := s.templatesRepo.Create(template); err != nil {
				return nil, status.Errorf(codes.Internal, "failed to create template: %v", err)
			}
		} else {
			// Update if client version is newer
			if template.SyncVersion > existing.SyncVersion {
				if err := s.templatesRepo.Update(template); err != nil {
					return nil, status.Errorf(codes.Internal, "failed to update template: %v", err)
				}
			}
		}
	}

	// Get server updates since last sync
	lastSync := time.Unix(req.LastSyncTimestamp, 0)
	updatedTemplates, err := s.templatesRepo.GetUpdatedSince(lastSync)
	if err != nil {
		return nil, status.Errorf(codes.Internal, "failed to get updated templates: %v", err)
	}

	// Convert to protobuf
	var templatesPb []*pb.UserTemplate
	var deletedIds []string

	for _, template := range updatedTemplates {
		if template.DeletedAt != nil {
			deletedIds = append(deletedIds, template.ID)
		} else {
			templatesPb = append(templatesPb, templateToProto(template))
		}
	}

	return &pb.SyncTemplatesResponse{
		ServerUpdates:   templatesPb,
		DeletedIds:      deletedIds,
		ServerTimestamp: time.Now().Unix(),
	}, nil
}

// CreateUser creates a new user
func (s *UsersService) CreateUser(ctx context.Context, req *pb.User) (*pb.User, error) {
	user := protoToUser(req)

	if err := s.usersRepo.Create(user); err != nil {
		return nil, status.Errorf(codes.Internal, "failed to create user: %v", err)
	}

	return userToProto(user), nil
}

// UpdateUser updates an existing user
func (s *UsersService) UpdateUser(ctx context.Context, req *pb.User) (*pb.User, error) {
	user := protoToUser(req)

	if err := s.usersRepo.Update(user); err != nil {
		return nil, status.Errorf(codes.Internal, "failed to update user: %v", err)
	}

	return userToProto(user), nil
}

// DeleteUser soft deletes a user
func (s *UsersService) DeleteUser(ctx context.Context, req *pb.DeleteUserRequest) (*pb.DeleteUserResponse, error) {
	if err := s.usersRepo.Delete(req.Id); err != nil {
		return nil, status.Errorf(codes.Internal, "failed to delete user: %v", err)
	}

	return &pb.DeleteUserResponse{Success: true}, nil
}

// GetAllUsers retrieves all users
func (s *UsersService) GetAllUsers(ctx context.Context, req *pb.GetUsersRequest) (*pb.GetUsersResponse, error) {
	users, err := s.usersRepo.GetAll()
	if err != nil {
		return nil, status.Errorf(codes.Internal, "failed to get users: %v", err)
	}

	var usersPb []*pb.User
	for _, user := range users {
		usersPb = append(usersPb, userToProto(user))
	}

	return &pb.GetUsersResponse{Users: usersPb}, nil
}

// CreateTemplate creates a new template
func (s *UsersService) CreateTemplate(ctx context.Context, req *pb.UserTemplate) (*pb.UserTemplate, error) {
	template := protoToTemplate(req)

	if err := s.templatesRepo.Create(template); err != nil {
		return nil, status.Errorf(codes.Internal, "failed to create template: %v", err)
	}

	return templateToProto(template), nil
}

// UpdateTemplate updates an existing template
func (s *UsersService) UpdateTemplate(ctx context.Context, req *pb.UserTemplate) (*pb.UserTemplate, error) {
	template := protoToTemplate(req)

	if err := s.templatesRepo.Update(template); err != nil {
		return nil, status.Errorf(codes.Internal, "failed to update template: %v", err)
	}

	return templateToProto(template), nil
}

// DeleteTemplate soft deletes a template
func (s *UsersService) DeleteTemplate(ctx context.Context, req *pb.DeleteTemplateRequest) (*pb.DeleteTemplateResponse, error) {
	if err := s.templatesRepo.Delete(req.Id); err != nil {
		return nil, status.Errorf(codes.Internal, "failed to delete template: %v", err)
	}

	return &pb.DeleteTemplateResponse{Success: true}, nil
}

// GetAllTemplates retrieves all templates
func (s *UsersService) GetAllTemplates(ctx context.Context, req *pb.GetTemplatesRequest) (*pb.GetTemplatesResponse, error) {
	templates, err := s.templatesRepo.GetAll()
	if err != nil {
		return nil, status.Errorf(codes.Internal, "failed to get templates: %v", err)
	}

	var templatesPb []*pb.UserTemplate
	for _, template := range templates {
		templatesPb = append(templatesPb, templateToProto(template))
	}

	return &pb.GetTemplatesResponse{Templates: templatesPb}, nil
}

// Helper functions to convert between protobuf and models

func protoToUser(pb *pb.User) *models.User {
	user := &models.User{
		ID:             pb.Id,
		Name:           pb.Name,
		Role:           pb.Role,
		PasswordHash:   pb.PasswordHash,
		IsTemplateUser: pb.IsTemplateUser,
		CreatedAt:      time.Unix(pb.CreatedAt, 0),
		UpdatedAt:      time.Unix(pb.UpdatedAt, 0),
		SyncVersion:    pb.SyncVersion,
		NeedsSync:      pb.NeedsSync,
	}

	if pb.Percentage != nil {
		user.Percentage = pb.Percentage
	}

	if pb.DeletedAt != nil {
		deletedAt := time.Unix(*pb.DeletedAt, 0)
		user.DeletedAt = &deletedAt
	}

	if pb.LastSyncedAt != nil {
		lastSynced := time.Unix(*pb.LastSyncedAt, 0)
		user.LastSyncedAt = &lastSynced
	}

	return user
}

func userToProto(user *models.User) *pb.User {
	pbUser := &pb.User{
		Id:             user.ID,
		Name:           user.Name,
		Role:           user.Role,
		PasswordHash:   user.PasswordHash,
		IsTemplateUser: user.IsTemplateUser,
		CreatedAt:      user.CreatedAt.Unix(),
		UpdatedAt:      user.UpdatedAt.Unix(),
		SyncVersion:    user.SyncVersion,
		NeedsSync:      user.NeedsSync,
	}

	if user.Percentage != nil {
		pbUser.Percentage = user.Percentage
	}

	if user.DeletedAt != nil {
		deletedAt := user.DeletedAt.Unix()
		pbUser.DeletedAt = &deletedAt
	}

	if user.LastSyncedAt != nil {
		lastSynced := user.LastSyncedAt.Unix()
		pbUser.LastSyncedAt = &lastSynced
	}

	return pbUser
}

func protoToTemplate(pb *pb.UserTemplate) *models.UserTemplate {
	template := &models.UserTemplate{
		ID:           pb.Id,
		Role:         pb.Role,
		PasswordHash: pb.PasswordHash,
		Percentage:   pb.Percentage,
		CreatedAt:    time.Unix(pb.CreatedAt, 0),
		UpdatedAt:    time.Unix(pb.UpdatedAt, 0),
		SyncVersion:  pb.SyncVersion,
		NeedsSync:    pb.NeedsSync,
	}

	if pb.DeletedAt != nil {
		deletedAt := time.Unix(*pb.DeletedAt, 0)
		template.DeletedAt = &deletedAt
	}

	if pb.LastSyncedAt != nil {
		lastSynced := time.Unix(*pb.LastSyncedAt, 0)
		template.LastSyncedAt = &lastSynced
	}

	return template
}

func templateToProto(template *models.UserTemplate) *pb.UserTemplate {
	pbTemplate := &pb.UserTemplate{
		Id:           template.ID,
		Role:         template.Role,
		PasswordHash: template.PasswordHash,
		Percentage:   template.Percentage,
		CreatedAt:    template.CreatedAt.Unix(),
		UpdatedAt:    template.UpdatedAt.Unix(),
		SyncVersion:  template.SyncVersion,
		NeedsSync:    template.NeedsSync,
	}

	if template.DeletedAt != nil {
		deletedAt := template.DeletedAt.Unix()
		pbTemplate.DeletedAt = &deletedAt
	}

	if template.LastSyncedAt != nil {
		lastSynced := template.LastSyncedAt.Unix()
		pbTemplate.LastSyncedAt = &lastSynced
	}

	return pbTemplate
}
