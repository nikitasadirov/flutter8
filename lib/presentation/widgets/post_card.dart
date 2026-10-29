import 'package:flutter/material.dart';

import '../../data/models/post.dart';

class PostCard extends StatelessWidget {
  const PostCard({
    required this.post,
    required this.authorName,
    required this.onTap,
    super.key,
  });

  final Post post;
  final String authorName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    elevation: 0,
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: const BorderSide(color: Color(0xFFE9ECF3)),
    ),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xFFEFF1FF),
                  child: Text(
                    post.userId.toString(),
                    style: const TextStyle(
                      color: Color(0xFF4355DB),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    authorName,
                    style: Theme.of(context).textTheme.labelLarge
                        ?.copyWith(color: const Color(0xFF69728A)),
                  ),
                ),
                if (post.locallyCreated)
                  const _LocalBadge()
                else
                  Text(
                    '#${post.id}',
                    style: Theme.of(context).textTheme.labelMedium
                        ?.copyWith(color: const Color(0xFF8A92A8)),
                  ),
              ],
            ),
            const SizedBox(height: 13),
            Text(
              post.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800, height: 1.25),
            ),
            const SizedBox(height: 7),
            Text(
              post.body,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: const Color(0xFF737D95), height: 1.45),
            ),
            const SizedBox(height: 11),
            const Row(
              children: [
                Text(
                  'Подробнее',
                  style: TextStyle(
                    color: Color(0xFF4355DB),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: Color(0xFF4355DB),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _LocalBadge extends StatelessWidget {
  const _LocalBadge();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF1DA),
      borderRadius: BorderRadius.circular(20),
    ),
    child: const Text(
      'локально',
      style: TextStyle(
        color: Color(0xFF9A6200),
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}
