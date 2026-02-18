# Team Workflow Guide

This document describes how team members collaborate on the OpenStack infrastructure project.

## Git Workflow

### Branching Strategy

1. **`main`**: Production-ready code
   - Protected branch
   - Requires merge request
   - Requires approvals (see CODEOWNERS)

2. **`develop`**: Integration branch (optional)
   - Feature branches merge here first
   - Testing happens here
   - Stable code merges to `main`

3. **`feature/*`**: Feature branches
   - One branch per feature/change
   - Naming: `feature/nova-live-migration`, `feature/ceph-pool-tuning`

4. **`hotfix/*`**: Emergency fixes
   - For critical production issues
   - Can merge directly to `main` with fast-track approval

### Commit Messages

Follow conventional commits:

```
type(scope): description

[optional body]

[optional footer]
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `refactor`: Code refactoring
- `test`: Tests
- `chore`: Maintenance

Examples:

```
feat(nova): add live migration configuration

Configure live migration with auto-converge and post-copy
for better VM migration performance.

fix(ceph): correct OSD device class assignment

The SSD devices were incorrectly assigned to HDD pool.
```

## Daily Workflow

### Starting Work

1. **Sync with Main**

   ```bash
   git checkout main
   git pull origin main
   ```

2. **Create Feature Branch**

   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make Changes**

   - Edit configuration files
   - Update documentation
   - Add scripts if needed

4. **Test Locally** (if possible)

   ```bash
   # Run linting
   yamllint inventory/ kolla/ ceph/
   ansible-lint inventory/

   # Validate syntax
   ansible-inventory -i inventory/production/hosts.yml --list
   ```

5. **Commit Changes**

   ```bash
   git add .
   git commit -m "feat(nova): add live migration config"
   ```

6. **Push Branch**

   ```bash
   git push origin feature/your-feature-name
   ```

### Creating Merge Request

1. **Open GitLab UI**

   - Go to Merge Requests → New Merge Request
   - Select your feature branch
   - Target: `main` (or `develop` if using)

2. **Fill MR Details**

   - **Title**: Clear description of changes
   - **Description**: 
     - What changed and why
     - Testing performed
     - Related issues/tickets
   - **Assignee**: Assign to yourself
   - **Reviewers**: Assign based on CODEOWNERS

3. **Wait for CI Pipeline**

   - Pipeline runs automatically
   - All jobs must pass (or have approval for failures)
   - Fix any lint/validation errors

4. **Address Review Comments**

   - Reviewers will comment
   - Make requested changes
   - Push updates to same branch
   - MR updates automatically

5. **Merge**

   - Once approved (required approvals met)
   - Merge button becomes available
   - Choose merge strategy:
     - **Merge commit**: Preserves branch history
     - **Squash and merge**: Single commit (recommended for feature branches)
     - **Rebase and merge**: Linear history

### After Merge

1. **Clean Up**

   ```bash
   git checkout main
   git pull origin main
   git branch -d feature/your-feature-name  # Delete local branch
   ```

2. **Deploy** (if needed)

   - Senior engineer triggers deployment via GitLab CI/CD
   - Monitor deployment pipeline
   - Verify changes in production

## Team Responsibilities

### Senior Engineer

- Architecture decisions
- Code reviews (all critical changes)
- Deployment approvals
- Mentoring team members
- Emergency response

### Mid-Level Engineers

- Component ownership
- Code reviews (assigned components)
- Mentoring juniors
- Feature development
- Documentation

### Junior Engineers

- Feature development
- Testing
- Documentation
- Learning and asking questions
- Following established patterns

## Component Ownership

### Current Assignments (To Be Defined)

Once teams are organized, update CODEOWNERS with:

- **Nova Team**: `/kolla/config/nova.conf`, compute-related vars
- **Neutron Team**: `/kolla/config/neutron.conf`, network-related vars
- **Storage Team**: `/ceph/`, `/kolla/config/cinder.conf`, `/kolla/config/glance-api.conf`
- **Infrastructure Team**: `/inventory/`, `/kolla/globals.yml`, `/.gitlab-ci.yml`

## Code Review Guidelines

### For Reviewers

- **Be Constructive**: Provide actionable feedback
- **Be Timely**: Review within 24-48 hours
- **Be Thorough**: Check logic, syntax, security, documentation
- **Be Kind**: Remember everyone is learning

### For Authors

- **Be Patient**: Reviews take time
- **Be Responsive**: Address comments promptly
- **Be Open**: Accept feedback gracefully
- **Be Proactive**: Ask questions if unclear

## Communication

### GitLab Issues

- Use for: Bugs, feature requests, questions
- Label appropriately: `bug`, `enhancement`, `question`, `documentation`
- Assign to relevant team members

### GitLab Discussions

- Use for: General questions, architecture discussions
- Less formal than issues
- Good for brainstorming

### Slack/Teams (if available)

- Use for: Quick questions, coordination
- Don't use for: Important decisions (use GitLab)

## Best Practices

### Configuration Changes

1. **Always Test**: Test in staging if available
2. **Document**: Update docs/ if behavior changes
3. **Version**: Tag releases for tracking
4. **Backup**: Backup before major changes

### Secrets Management

1. **Never Commit**: Unencrypted secrets
2. **Use Vault**: Encrypt with ansible-vault
3. **Rotate Regularly**: Change passwords periodically
4. **Limit Access**: Only necessary people have vault password

### Documentation

1. **Keep Updated**: Update docs with code changes
2. **Be Clear**: Write for your future self
3. **Include Examples**: Show, don't just tell
4. **Review**: Have docs reviewed like code

## Emergency Procedures

### Critical Production Issue

1. **Assess**: Determine severity and impact
2. **Notify**: Alert team via Slack/Teams
3. **Create Hotfix**: Branch from `main`
4. **Fast-Track Review**: Senior engineer reviews immediately
5. **Deploy**: Deploy via GitLab CI/CD
6. **Document**: Create issue for post-mortem
7. **Follow-Up**: Implement proper fix later

### Rollback

1. **Identify**: Which commit/tag to rollback to
2. **Create Rollback Branch**: From previous stable tag
3. **Review**: Get approval (can be fast-tracked)
4. **Deploy**: Deploy rollback via CI/CD
5. **Verify**: Confirm issue resolved
6. **Investigate**: Root cause analysis

## Learning Resources

- **Kolla-Ansible**: https://docs.openstack.org/kolla-ansible/
- **Ceph**: https://docs.ceph.com/
- **OpenStack**: https://docs.openstack.org/
- **Ansible**: https://docs.ansible.com/
- **GitLab CI/CD**: https://docs.gitlab.com/ee/ci/

## Questions?

- Ask in GitLab Discussions
- Contact senior engineer
- Check documentation first
- Review similar MRs for examples
